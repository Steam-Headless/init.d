#!/usr/bin/env bash
#
# Sunshine importer for Heroic (images via Heroic cache URL hashing)
#
# - Reads per-game JSONs from /home/default/.config/heroic/GamesConfig/
# - Launch command (exact):
#     /usr/bin/sunshine-run /home/default/Applications/Heroic.AppImage --no-gui heroic://launch/<game_id>
# - Poster: scan Heroic JSONs for objects whose id == <game_id>, collect URLs only from those
#           objects, hash each URL (sha256) and match a file in images-cache, prefer “cover-like”.
# - Converts found image to 600x900 PNG at ~/.local/share/posters/<game_id>.png
#
set -Eeuo pipefail

# -------- Fixed Paths --------
USER_HOME="$HOME"
SUNSHINE_CONF="$USER_HOME/.config/sunshine/apps.json"
POSTER_DIR="$USER_HOME/.local/share/posters"
HEROIC_CONF_ROOT="/home/default/.config/heroic"
HEROIC_CFG_ROOT="$HEROIC_CONF_ROOT/GamesConfig"
HEROIC_IMAGES_CACHE="$HEROIC_CONF_ROOT/images-cache"
HEROIC_APPIMAGE="/home/default/Applications/Heroic.AppImage"

YELLOW="\033[33m"; RESET="\033[0m"

# -------- Deps --------
need_bins=(jq sha256sum convert)
for b in "${need_bins[@]}"; do
  command -v "$b" >/dev/null 2>&1 || { echo "[ERR] Missing dependency: $b"; exit 1; }
done

# -------- Setup --------
mkdir -p "$POSTER_DIR" "$(dirname "$SUNSHINE_CONF")"
if ! jq . "$SUNSHINE_CONF" >/dev/null 2>&1; then echo '{"apps":[]}' >"$SUNSHINE_CONF"; fi

LOCK_FD=200
LOCK_FILE="${SUNSHINE_CONF}.lock"
exec {LOCK_FD}> "$LOCK_FILE" || true
command -v flock >/dev/null 2>&1 && flock -n "$LOCK_FD" || true

tmpwrite(){ local t; t="$(mktemp "${SUNSHINE_CONF}.XXXXXX")"; cat >"$t"; mv -f "$t" "$SUNSHINE_CONF"; }
jq_safe_merge(){ local e="$1"; jq --argjson entry "$e" '.apps = ((.apps // []) + [$entry])' "$SUNSHINE_CONF" | tmpwrite; }

remove_entries(){
  jq '.apps = ((.apps // []) | map(select(.output != "HG-json.txt")))' "$SUNSHINE_CONF" | tmpwrite
}

# -------- Helpers --------

# Display name from winePrefix tail; fallback to id
name_from_prefix_or_id(){
  local p="$1" id="$2" n; n="$(basename "$p" 2>/dev/null || true)"
  [[ -n "$n" && "$n" != "/" && "$n" != "." ]] && { echo "$n"; } || echo "$id"
}

# Extract candidate URLs ONLY from objects whose id/productId/app_name/etc == $gid
urls_for_gid_in_file(){
  local jf="$1" gid="$2"
  jq -r --arg id "$gid" '
    .. | objects
    | select(
        ( .id?            | tostring == $id ) or
        ( .productId?     | tostring == $id ) or
        ( .app_name?      | tostring == $id ) or
        ( .appName?       | tostring == $id ) or
        ( .appTitleId?    | tostring == $id ) or
        ( .game?.id?      | tostring == $id ) or
        ( .game?.productId?| tostring == $id )
      )
    | .. | strings
    | select(test("^https?://"; "i"))
  ' "$jf" 2>/dev/null | sed 's/[[:space:]]\+$//' | sort -u
}

# Prefer cover-ish URLs, then fall back to any
prioritize_urls(){
  awk '
    BEGIN{ IGNORECASE=1 }
    {
      if ($0 ~ /(cover|vertical|portrait|grid|imageType=Cover|boxart|tile|artwork)/) {
        print "A:"$0
      } else {
        print "B:"$0
      }
    }
  ' | sort | cut -c3-
}

# Map URLs -> first cache hit file (sha256(url) with/without common extensions)
first_cache_hit_from_urls(){
  local cache="$1"; shift
  local u key f
  for u in "$@"; do
    key="$(printf '%s' "$u" | sha256sum | awk '{print $1}')"
    # Heroic stores without extension; try with common ones too
    for ext in "" ".png" ".jpg" ".jpeg" ".webp"; do
      f="$cache/$key$ext"
      [[ -f "$f" ]] && { printf '%s\n' "$f"; return 0; }
    done
  done
  echo ""
}

# Find the cached image for a game id: scan JSONs referencing the id,
# pull only URLs from the matching object(s), prioritize cover-ish, then test cache.
find_cached_image_for_id(){
  local gid="$1" cache="$HEROIC_IMAGES_CACHE"
  [[ -d "$cache" ]] || { echo ""; return 0; }

  # JSONs that mention the id at all
  mapfile -t jfs < <(grep -RIl --include='*.json' -F "$gid" "$HEROIC_CONF_ROOT" 2>/dev/null | sort -u)
  (( ${#jfs[@]} )) || { echo ""; return 0; }

  # Collect URLs from matching objects only (dedup)
  declare -A seen=()
  mapfile -t urls < <(
    for jf in "${jfs[@]}"; do urls_for_gid_in_file "$jf" "$gid"; done \
      | awk '!seen[$0]++'
  )

  (( ${#urls[@]} )) || { echo ""; return 0; }

  # Prioritize then probe cache
  mapfile -t ordered < <(printf "%s\n" "${urls[@]}" | prioritize_urls)
  first_cache_hit_from_urls "$cache" "${ordered[@]}"
}

ensure_poster_from_cache_file(){
  local gid="$1" src="$2" out="$POSTER_DIR/${gid}.png"
  [[ -f "$src" ]] || { echo ""; return 0; }
  [[ -f "$out" ]] && { echo "$out"; return 0; }
  if convert "$src" -resize 600x900^ -gravity center -extent 600x900 "$out"; then
    echo "$out"
  else
    echo ""
  fi
}

make_entry_json(){
  local name="$1" detached_cmd="$2" image_path="${3:-}"
  if [[ -n "$image_path" ]]; then
    jq -n --arg name "$name" --arg output "HG-json.txt" --arg cmd "" \
          --arg detached "$detached_cmd" --arg image "$image_path" --arg workingdir "$USER_HOME" '{
      name:$name, output:$output, cmd:$cmd, detached:[$detached],
      "exclude-global-prep-cmd":"false", elevated:"false",
      "prep-cmd":[
        {"do":"/usr/bin/xfce4-minimise-all-windows","undo":"/usr/bin/sunshine-stop"},
        {"do":"","undo":"/usr/bin/xfce4-close-all-windows"}
      ],
      "image-path":$image, "working-dir":$workingdir }'
  else
    jq -n --arg name "$name" --arg output "HG-json.txt" --arg cmd "" \
          --arg detached "$detached_cmd" --arg workingdir "$USER_HOME" '{
      name:$name, output:$output, cmd:$cmd, detached:[$detached],
      "exclude-global-prep-cmd":"false", elevated:"false",
      "prep-cmd":[
        {"do":"/usr/bin/xfce4-minimise-all-windows","undo":"/usr/bin/sunshine-stop"},
        {"do":"","undo":"/usr/bin/xfce4-close-all-windows"}
      ],
      "working-dir":$workingdir }'
  fi
}

# -------- Main --------
cmd="${1:-""}"
if [[ "$cmd" == "remove" ]]; then
  remove_entries
  echo "[OK] Removed previously added Sunshine entries (output == HG-json.txt)."
  exit 0
fi

remove_entries

[[ -d "$HEROIC_CFG_ROOT" ]] || { echo "[ERR] Missing Heroic GamesConfig: $HEROIC_CFG_ROOT"; exit 1; }
[[ -d "$HEROIC_IMAGES_CACHE" ]] || echo "[WARN] Images cache not found: $HEROIC_IMAGES_CACHE"
[[ -e "$HEROIC_APPIMAGE" ]] || echo "[WARN] AppImage not found at $HEROIC_APPIMAGE"
[[ -x "$HEROIC_APPIMAGE" ]] || echo "[WARN] AppImage not executable; run: chmod +x \"$HEROIC_APPIMAGE\""

shopt -s nullglob
found_any=0
declare -A seen_ids=()

for jf in "$HEROIC_CFG_ROOT"/*.json; do
  mapfile -t ids < <(jq -r 'keys[] | select(. != "version" and . != "explicit")' "$jf" 2>/dev/null || true)
  for gid in "${ids[@]}"; do
    [[ -n "$gid" ]] || continue
    [[ -n "${seen_ids[$gid]+x}" ]] && continue
    seen_ids["$gid"]=1

    prefix="$(jq -r --arg k "$gid" '.[$k].winePrefix // ""' "$jf" 2>/dev/null || echo "")"
    gname="$(name_from_prefix_or_id "$prefix" "$gid")"

    detached_cmd="/usr/bin/sunshine-run /home/default/Applications/Heroic.AppImage --no-gui heroic://launch/$gid"

    poster_path=""
    cache_hit="$(find_cached_image_for_id "$gid")"
    if [[ -n "$cache_hit" ]]; then
      poster_path="$(ensure_poster_from_cache_file "$gid" "$cache_hit" || echo "")"
    fi
    poster_status="[NOP]"; [[ -n "$poster_path" ]] && poster_status="[POSTER]"

    entry_json="$(make_entry_json "$gname" "$detached_cmd" "$poster_path")"
    jq_safe_merge "$entry_json"; found_any=1

    echo -e "Heroic: ${YELLOW}$gname${RESET} (id: $gid) - [OK] $poster_status"
  done
done

if [[ "$found_any" -eq 0 ]]; then
  echo "[ERR] No games found under: $HEROIC_CFG_ROOT"
fi

echo "[OK] Sunshine configuration updated at: $SUNSHINE_CONF"

if [[ -x /usr/bin/sunshine-stop ]]; then
  echo "Restarting Sunshine to apply changes."
  /usr/bin/sunshine-stop || echo "[WARN] sunshine-stop returned an error"
else
  echo "[WARN] /usr/bin/sunshine-stop not found, skipping auto-stop."
fi
