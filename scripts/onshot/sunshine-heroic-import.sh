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

# -------- Rename options --------
RENAME_DESKTOP_LAUNCHER="yes"     # if "yes", rename "Desktop" -> "#1 Desktop" to have it in the top of the list
RENAME_BIGPICTURE_LAUNCHER="yes"  # if "yes", rename "Steam Big Picture" -> "Zz Steam Big Picture" to have it in the bottom of the list
RENAME_HEROIC_LAUNCHER="yes"      # if "yes", rename "Heroic" -> "Zz Heroic" to have it in the bottom of the list

# -------- Fixed Paths --------
USER_HOME="$HOME"
SUNSHINE_CONF="$USER_HOME/.config/sunshine/apps.json"
POSTER_DIR="$USER_HOME/.local/share/posters"
if [[ -d "/home/default/.local/share/posters" || -d "/home/default" ]]; then
  POSTER_DIR="/home/default/.local/share/posters"
fi
HEROIC_CONF_ROOT="/home/default/.config/heroic"
HEROIC_CFG_ROOT="$HEROIC_CONF_ROOT/GamesConfig"
HEROIC_IMAGES_CACHE="$HEROIC_CONF_ROOT/images-cache"
HEROIC_APPIMAGE="/home/default/Applications/Heroic.AppImage"

YELLOW="\033[33m"; RESET="\033[0m"

# Check if STEAMGRIDDB_API is defined in Docker env
if [[ -z "${STEAMGRIDDB_API+x}" ]]; then
  echo "[WARN] Docker env var STEAMGRIDDB_API is not set. SteamGridDB fallback posters will be skipped."
  STEAMGRIDDB_API=""
elif [[ -z "$STEAMGRIDDB_API" ]]; then
  echo "[WARN] Docker env var STEAMGRIDDB_API is empty. SteamGridDB fallback posters will be skipped."
else
  echo "[OK] STEAMGRIDDB_API key found. SteamGridDB will be used as fallback when no local poster is cached."
fi

# -------- Deps --------
need_bins=(jq sha256sum convert curl)
for b in "${need_bins[@]}"; do
  command -v "$b" >/dev/null 2>&1 || { echo "[ERR] Missing dependency: $b"; exit 1; }
done

# -------- Setup --------
mkdir -p "$POSTER_DIR" "$(dirname "$SUNSHINE_CONF")"
if ! jq . "$SUNSHINE_CONF" >/dev/null 2>&1; then echo '{"apps":[]}' >"$SUNSHINE_CONF"; fi

LOCK_FD=200
LOCK_FILE="${SUNSHINE_CONF}.lock"
exec {LOCK_FD}> "$LOCK_FILE" || true
if command -v flock >/dev/null 2>&1; then
  flock -n "$LOCK_FD" || echo "[WARN] could not acquire lock; proceeding cautiously."
fi

tmpwrite(){ local t; t="$(mktemp "${SUNSHINE_CONF}.XXXXXX")"; cat >"$t"; mv -f "$t" "$SUNSHINE_CONF"; }
jq_safe_merge(){ local e="$1"; jq --argjson entry "$e" '.apps = ((.apps // []) + [$entry])' "$SUNSHINE_CONF" | tmpwrite; }

remove_entries(){
  jq '.apps = ((.apps // []) | map(select(.output != "HG-json.txt")))' "$SUNSHINE_CONF" | tmpwrite
}

rename_builtin_launchers(){
  jq \
    --arg rename_desktop "$RENAME_DESKTOP_LAUNCHER" \
    --arg rename_bp "$RENAME_BIGPICTURE_LAUNCHER" \
    --arg rename_heroic "$RENAME_HEROIC_LAUNCHER" \
    '
    .apps = (
      (.apps // [])
      | map(
          if     ($rename_desktop == "yes" and .name == "Desktop") then .name = "#1 Desktop"
          elif   ($rename_bp == "yes" and .name == "Steam Big Picture") then .name = "Zz Steam Big Picture"
          elif   ($rename_heroic == "yes" and .name == "Heroic") then .name = "Zz Heroic"
          elif   ($rename_desktop == "no" and .name == "#1 Desktop") then .name = "Desktop"
          elif   ($rename_bp == "no" and .name == "Zz Steam Big Picture") then .name = "Steam Big Picture"
          elif   ($rename_heroic == "no" and .name == "Zz Heroic") then .name = "Heroic"
          else .
          end
        )
    )
    ' "$SUNSHINE_CONF" | tmpwrite
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

finalize_poster_file(){
  local out_png="$1"

  chmod 0644 "$out_png" 2>/dev/null || true
  if [[ "$out_png" == /home/default/* ]] && id -u default >/dev/null 2>&1; then
    chown default:default "$out_png" 2>/dev/null || true
  fi
}

convert_poster_to_png(){
  local src="$1" name="$2" out_png="$3"

  if ! convert "$src" -resize 600x900\! \
      -gravity South -fill white -undercolor '#00000080' -geometry +0-40 -pointsize 50 \
      -background none -size 580x caption:"$name" \
      -background none -alpha set -compose over -composite "$out_png" 2>/dev/null; then
    echo "[WARN] poster caption overlay failed, retrying with plain resize." >&2
    convert "$src" -resize 600x900\! "$out_png" 2>/dev/null || return 1
  fi

  [[ -s "$out_png" ]] || return 1
  finalize_poster_file "$out_png"
}

ensure_poster_from_cache_file(){
  local gid="$1" name="$2" src="$3" out="$POSTER_DIR/${gid}.png"
  [[ -f "$src" ]] || { echo ""; return 0; }

  rm -f "$out"
  if convert_poster_to_png "$src" "$name" "$out"; then
    echo "$out"
  else
    echo ""
  fi
}

get_sgdb_game_id(){
  local platform="$1" platform_id="$2"
  local response

  response="$(curl -sS "https://www.steamgriddb.com/api/v2/games/$platform/$platform_id" \
    -H "Authorization: Bearer $STEAMGRIDDB_API")"

  jq -r '.data.id // empty' <<< "$response"
}

get_ranked_sgdb_poster_url(){
  local platform="$1" platform_id="$2"
  [[ -n "$STEAMGRIDDB_API" ]] || { echo ""; return 0; }
  local sgdb_game_id base response url

  sgdb_game_id="$(get_sgdb_game_id "$platform" "$platform_id")"
  if [[ -n "$sgdb_game_id" ]]; then
    base="https://www.steamgriddb.com/api/v2/grids/game/$sgdb_game_id"
  else
    base="https://www.steamgriddb.com/api/v2/grids/$platform/$platform_id"
  fi

  response="$(curl -sS "$base?dimensions=600x900&mimes=image/png&nsfw=any&humor=any&types=static&limit=50" \
    -H "Authorization: Bearer $STEAMGRIDDB_API")"

  url="$(jq -r '
    def num_or_zero: if . == null then 0 else (try tonumber catch 0) end;
    [ .data[]? | . + {
      _rank: (
        (if .width == 600 and .height == 900 then 2000 else 0 end) +
        (if .height > .width then 1000 else 0 end) +
        (if .width > 0 and (.height / .width) >= 1.3 then 500 else 0 end) +
        (if .mime == "image/png" then 200 else 0 end) +
        ([ (
          if .upvotes != null or .downvotes != null then
            ((.upvotes | num_or_zero) - (.downvotes | num_or_zero))
          elif .likes != null then
            (.likes | num_or_zero)
          else
            (.score | num_or_zero)
          end
        ), 100 ] | min)
      ),
      _engagement: (
        if .upvotes != null or .downvotes != null then
          ((.upvotes | num_or_zero) - (.downvotes | num_or_zero))
        elif .likes != null then
          (.likes | num_or_zero)
        else
          (.score | num_or_zero)
        end
      ),
      _id: (.id | num_or_zero)
    }]
    | sort_by([._rank, ._engagement, -._id])
    | last.url // empty
  ' <<< "$response")"

  if [[ -z "$url" && "${STEAMGRIDDB_DEBUG:-}" == "1" ]]; then
    echo "[DEBUG] heroic/$platform_id: $(jq -c '{success:.success, count:(.data|length), sample:.data[0]}' <<< "$response" 2>/dev/null)" >&2
  elif [[ "${STEAMGRIDDB_DEBUG:-}" == "1" ]]; then
    echo "[DEBUG] heroic/$platform_id: selected $(jq -r '
      def num_or_zero: if . == null then 0 else (try tonumber catch 0) end;
      [ .data[]? | . + {
        _rank: (
          (if .width == 600 and .height == 900 then 2000 else 0 end) +
          (if .height > .width then 1000 else 0 end) +
          (if .width > 0 and (.height / .width) >= 1.3 then 500 else 0 end) +
          (if .mime == "image/png" then 200 else 0 end) +
          ([ (
            if .upvotes != null or .downvotes != null then
              ((.upvotes | num_or_zero) - (.downvotes | num_or_zero))
            elif .likes != null then
              (.likes | num_or_zero)
            else
              (.score | num_or_zero)
            end
          ), 100 ] | min)
        ),
        _engagement: (
          if .upvotes != null or .downvotes != null then
            ((.upvotes | num_or_zero) - (.downvotes | num_or_zero))
          elif .likes != null then
            (.likes | num_or_zero)
          else
            (.score | num_or_zero)
          end
        ),
        _id: (.id | num_or_zero)
      }]
      | sort_by([._rank, ._engagement, -._id])
      | last
      | {id, score, likes, upvotes, downvotes, width, height, mime, url}
    ' <<< "$response" 2>/dev/null)" >&2
  fi

  echo "$url"
}

ensure_poster_from_sgdb(){
  local gid="$1" name="$2" out_png="$POSTER_DIR/${gid}.png"
  local url tmpfile

  url="$(get_ranked_sgdb_poster_url heroic "$gid")"
  if [[ -z "$url" ]]; then
    echo "[WARN] $gid: no poster URL found on SteamGridDB." >&2
    echo ""
    return 0
  fi

  echo "[POSTER] $gid: downloading poster from $url" >&2
  rm -f "$out_png"

  tmpfile="$(mktemp "$POSTER_DIR/${gid}.dl.XXXXXX")"
  if curl -fsSL "$url" -o "$tmpfile"; then
    if convert_poster_to_png "$tmpfile" "$name" "$out_png"; then
      rm -f "$tmpfile"
      echo "$out_png"
    else
      echo "[ERR] $gid: convert failed entirely." >&2
      rm -f "$tmpfile"
      echo ""
    fi
  else
    echo "[ERR] $gid: failed to download poster from $url" >&2
    rm -f "$tmpfile"
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
      poster_path="$(ensure_poster_from_cache_file "$gid" "$gname" "$cache_hit" || echo "")"
    fi
    # Fallback: fetch from SteamGridDB if no local cache hit and API key is set
    if [[ -z "$poster_path" && -n "$STEAMGRIDDB_API" ]]; then
      poster_path="$(ensure_poster_from_sgdb "$gid" "$gname" || echo "")"
    fi
    poster_status="[NOP]"; [[ -n "$poster_path" ]] && poster_status="[POSTER]"

    entry_json="$(make_entry_json "$gname" "$detached_cmd" "$poster_path")"
    jq_safe_merge "$entry_json"; found_any=1

    echo -e "Heroic: ${YELLOW}$gname${RESET} (id: $gid) - [OK] $poster_status"
  done
done

rename_builtin_launchers

if [[ "$found_any" -eq 0 ]]; then
  echo "[ERR] No games found under: $HEROIC_CFG_ROOT"
fi

echo "[OK] Sunshine configuration updated at: $SUNSHINE_CONF"

# -------- Post-run: restart Sunshine service so new apps.json is picked up --------
# sunshine-stop is a per-game session cleanup hook (kills sunshine-run on disconnect),
# NOT a service restart. Use supervisorctl to properly restart the Sunshine service.
if command -v supervisorctl >/dev/null 2>&1; then
  echo "[OK] Restarting Sunshine service via supervisorctl to apply changes."
  supervisorctl restart sunshine || echo "[WARN] supervisorctl restart sunshine returned an error"
else
  echo "[WARN] supervisorctl not found, skipping Sunshine restart. Restart it manually to apply changes."
fi
