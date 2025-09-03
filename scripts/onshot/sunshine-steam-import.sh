#!/usr/bin/env bash
#
# Usage:
#   ./sunshine-steam-import.sh           # remove old entries, then import + posters (if API key set)
#   ./sunshine-steam-import.sh remove    # just remove previously added entries
#
# Docker usage:
#   Provide the SteamGridDB API key as a Docker environment variable:
#     docker run -e STEAMGRIDDB_API=your_api_key_here ...
#   If STEAMGRIDDB_API is not set, posters will be skipped.
#
# Paths (no env overrides):
#   - Sunshine config:  $HOME/.config/sunshine/apps.json
#   - Posters:          $HOME/.local/share/posters
#   - Steam library:    auto-detected ? first "steamapps" folder found under /mnt/games/
#                       (If none is found, the script exits with an error.)
#
# Notes:
#   - Entries added by this script are removed on each run via marker: output == "SH-run.txt".
#   - Global Prep Commands remain enabled: "exclude-global-prep-cmd": "false".
#   - Console-friendly log markers: [OK], [ERR], [WARN], [SKIP], [POSTER], [NOP].

set -Eeuo pipefail

# -------- Rename options --------
RENAME_DESKTOP_LAUNCHER="yes"     # if "yes", rename "Desktop" -> "#1 Desktop" to have it in the top of the list
RENAME_BIGPICTURE_LAUNCHER="yes"  # if "yes", rename "Steam Big Picture" -> "Zz Steam Big Picture" to have it in the bottom of the list
RENAME_HEROIC_LAUNCHER="yes"      # if "yes", rename "Heroic" -> "Zz Heroic" to have it in the bottom of the list

# -------- Fixed Paths (no overrides) --------
USER_HOME="$HOME"
SUNSHINE_CONF="$USER_HOME/.config/sunshine/apps.json"
POSTER_DIR="$USER_HOME/.local/share/posters"

# Auto-detect STEAM_LIBRARY_DIR by finding first "steamapps" under /mnt/games
STEAM_LIBRARY_DIR="$(find /mnt/games -type d -name steamapps 2>/dev/null | head -n 1 || true)"
if [[ -z "$STEAM_LIBRARY_DIR" ]]; then
  echo "[ERR] Could not find a 'steamapps' folder under /mnt/games/"
  echo "      Mount your Steam library into the container (e.g., /mnt/games/YourLibrary/steamapps)."
  exit 1
else
  echo "[OK] Found Steam library: $STEAM_LIBRARY_DIR"
fi

# Check if STEAMGRIDDB_API is defined in Docker env
if [[ -z "${STEAMGRIDDB_API+x}" ]]; then
  echo "[WARN] Docker env var STEAMGRIDDB_API is not set. Posters will be skipped."
  STEAMGRIDDB_API=""
elif [[ -z "$STEAMGRIDDB_API" ]]; then
  echo "[WARN] Docker env var STEAMGRIDDB_API is empty. Posters will be skipped."
fi

# Blacklist patterns (case-insensitive match), games to not import
BLACKLIST=(
  "Runtime"
  "Proton"
  "SDK"
  "Dedicated"
  "Workshop"
  "Big Picture"
  "Source"
  "Linux Runtime"
  "Redistributables"
  "Desktop Mode"
)

# Colors
YELLOW="\033[33m"
RESET="\033[0m"

# -------- Helpers --------
need_bins=(jq curl convert)
for b in "${need_bins[@]}"; do
  command -v "$b" >/dev/null 2>&1 || { echo "[ERR] Missing dependency: $b"; exit 1; }
done

mkdir -p "$POSTER_DIR" "$(dirname "$SUNSHINE_CONF")"
if ! jq . "$SUNSHINE_CONF" >/dev/null 2>&1; then
  echo '{"apps":[]}' >"$SUNSHINE_CONF"
fi

LOCK_FD=200
LOCK_FILE="${SUNSHINE_CONF}.lock"
exec {LOCK_FD}> "$LOCK_FILE" || true
flock -n "$LOCK_FD" || echo "[WARN] could not acquire lock; proceeding cautiously."

tmpwrite() {
  local tmp
  tmp="$(mktemp "${SUNSHINE_CONF}.XXXXXX")"
  cat > "$tmp"
  mv -f "$tmp" "$SUNSHINE_CONF"
}

jq_safe_merge() {
  local entry="$1"
  jq --argjson entry "$entry" '
    .apps = ( (.apps // []) + [$entry] )
  ' "$SUNSHINE_CONF" | tmpwrite
}

# Remove only entries previously added by this script (marker: output == "SH-run.txt")
remove_entries() {
  jq '
    .apps = ( (.apps // []) | map(select(.output != "SH-run.txt")) )
  ' "$SUNSHINE_CONF" | tmpwrite
}

# Rename existing launchers (not removed) according to toggles above
rename_builtin_launchers() {
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

get_poster_url() {
  local appid="$1"
  [[ -n "$STEAMGRIDDB_API" ]] || { echo ""; return 0; }
  curl -sS "https://www.steamgriddb.com/api/v2/grids/steam/$appid?dimensions=600x900" \
    -H "Authorization: Bearer $STEAMGRIDDB_API" \
  | jq -r '.data[0].url // empty'
}

ensure_poster() {
  local appid="$1" name="$2" out_png="$POSTER_DIR/$appid.png"
  [[ -f "$out_png" ]] && { echo "$out_png"; return 0; }
  local url; url="$(get_poster_url "$appid")"
  [[ -n "$url" ]] || { echo ""; return 0; }

  local tmpfile
  tmpfile="$(mktemp "$POSTER_DIR/${appid}.dl.XXXXXX")"
  if curl -fsSL "$url" -o "$tmpfile"; then
    convert "$tmpfile" -resize 600x900\! \
      -gravity South -fill white -undercolor '#00000080' -geometry +0-40 -pointsize 50 \
      -background none -size 580x caption:"$name" \
      -background none -alpha set -compose over -composite "$out_png" \
      || { rm -f "$tmpfile"; echo ""; return 0; }
    rm -f "$tmpfile"
    echo "$out_png"
  else
    rm -f "$tmpfile"
    echo ""
  fi
}

make_entry_json() {
  local name="$1" appid="$2" image_path="${3:-}"
  local game_run="/usr/bin/sunshine-run /usr/games/steam steam://rungameid/$appid"

  if [[ -n "$image_path" ]]; then
    jq -n \
      --arg name "$name" \
      --arg output "SH-run.txt" \
      --arg cmd "" \
      --arg detached "$game_run" \
      --arg image "$image_path" \
      --arg workingdir "$USER_HOME" \
      '{
        name: $name,
        output: $output,
        cmd: $cmd,
        detached: [ $detached ],
        "exclude-global-prep-cmd": "false",
        elevated: "false",
        "prep-cmd": [
          {"do": "/usr/bin/xfce4-minimise-all-windows", "undo": "/usr/bin/sunshine-stop"},
          {"do": "", "undo": "/usr/bin/xfce4-close-all-windows"}
        ],
        "image-path": $image,
        "working-dir": $workingdir
      }'
  else
    jq -n \
      --arg name "$name" \
      --arg output "SH-run.txt" \
      --arg cmd "" \
      --arg detached "$game_run" \
      --arg workingdir "$USER_HOME" \
      '{
        name: $name,
        output: $output,
        cmd: $cmd,
        detached: [ $detached ],
        "exclude-global-prep-cmd": "false",
        elevated: "false",
        "prep-cmd": [
          {"do": "/usr/bin/xfce4-minimise-all-windows", "undo": "/usr/bin/sunshine-stop"},
          {"do": "", "undo": "/usr/bin/xfce4-close-all-windows"}
        ],
        "working-dir": $workingdir
      }'
  fi
}

parse_manifest() {
  local acf="$1"
  local appid name
  appid="$(basename "$acf" | sed -E 's/^appmanifest_([0-9]+)\.acf$/\1/')"
  if [[ ! "$appid" =~ ^[0-9]+$ ]]; then
    appid="$(grep -oE '^\s*"appid"\s*"[0-9]+"' "$acf" | sed -E 's/.*"([0-9]+)".*/\1/' || true)"
  fi
  name="$(grep -oE '^\s*"name"\s*"[^"]+"' "$acf" | sed -E 's/.*"([^"]+)".*/\1/' || true)"
  [[ -n "$appid" && -n "$name" ]] && echo "${appid}|${name}" || true
}

is_blacklisted() {
  local name_lower
  name_lower="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  for pat in "${BLACKLIST[@]}"; do
    local pat_lower
    pat_lower="$(echo "$pat" | tr '[:upper:]' '[:lower:]')"
    if [[ "$name_lower" == *"$pat_lower"* ]]; then
      return 0
    fi
  done
  return 1
}

# -------- Main --------
cmd="${1:-""}"

if [[ "$cmd" == "remove" ]]; then
  remove_entries
  echo "[OK] Removed previously added Sunshine entries (output == SH-run.txt)."
  exit 0
fi

# Start fresh: remove our previously-added entries
remove_entries

shopt -s nullglob
found_any=0
for acf in "$STEAM_LIBRARY_DIR"/appmanifest_*.acf; do
  line="$(parse_manifest "$acf" || true)"
  [[ -n "$line" ]] || continue
  found_any=1

  appid="${line%%|*}"
  name="${line#*|}"

  if is_blacklisted "$name"; then
    echo -e "Game: ${YELLOW}$name${RESET} (appid $appid) - [SKIP] [NOP]"
    continue
  fi

  poster_path=""
  poster_status="[NOP]"
  if [[ -n "$STEAMGRIDDB_API" ]]; then
    poster_path="$(ensure_poster "$appid" "$name" || echo "")"
    [[ -n "$poster_path" ]] && poster_status="[POSTER]"
  fi

  entry_json="$(make_entry_json "$name" "$appid" "$poster_path")"
  jq_safe_merge "$entry_json"

  echo -e "Game: ${YELLOW}$name${RESET} (appid $appid) - [OK] $poster_status"
done

# Apply optional renames to any remaining (non-removed) launchers
rename_builtin_launchers

if [[ "$found_any" -eq 0 ]]; then
  echo "[ERR] No appmanifest_*.acf files found under: $STEAM_LIBRARY_DIR"
  echo "      Check your /mnt/games/ mount or library layout."
fi
echo "[OK] Sunshine configuration updated at: $SUNSHINE_CONF"

# -------- Post-run: stop Sunshine session so new config is picked up --------
if [[ -x /usr/bin/sunshine-stop ]]; then
  echo "Restarting Sunshine to apply changes."
  /usr/bin/sunshine-stop || echo "[WARN] sunshine-stop returned an error"
else
  echo "[WARN] /usr/bin/sunshine-stop not found, skipping auto-stop."
fi

