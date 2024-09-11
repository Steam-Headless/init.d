#!/bin/bash
steamgriddb_api="INSERTSTEAMGRIDDBAPI"
sunshine_conf=${USER_HOME:?}/.config/sunshine/apps.json
poster_folder=${USER_HOME:?}/.local/share/posters

# Steam apps folder path (change if needed)
STEAM_LIBRARY_DIR="/mnt/games/SteamLibrary/steamapps"

get_poster() {
    local appid="$1"
    local response
    response=$(curl -s "https://www.steamgriddb.com/api/v2/grids/steam/$appid" \
        -H "Authorization: Bearer $steamgriddb_api")
    echo "$response" | jq -r '.data[0].url'
}

function addEntry {
    cat <<EOF
    {
      "name": "$1",
      "output": "SH-run.txt",
      "cmd": "",
      "detached": [
        "$2"
      ],
      "exclude-global-prep-cmd": "true",
      "elevated": "false",
      "prep-cmd": [
        {
            "do": "/usr/bin/xfce4-minimise-all-windows",
            "undo": "/usr/bin/sunshine-stop"
        },
        {
          "do": "",
          "undo": "/usr/bin/xfce4-close-all-windows"
        }
      ],
      "image-path": "$3",
      "working-dir": "/home/default"
    }
EOF
}

function removeEntries {
  # Remove previously added entries
  cat ${sunshine_conf} | jq 'del(.apps[] | select(.output == "SH-run.txt"))' > /tmp/sunshine.json 
  mv -f /tmp/sunshine.json ${sunshine_conf}
}

removeEntries

# Loop through all .acf files in the library folder
for acf_file in "$STEAM_LIBRARY_DIR"/*.acf; do
    if [[ -f "$acf_file" ]]; then
        # Extract appid from the .acf file
        appid=$(grep -oP '^\s*"appid"\s*"\K\d+' "$acf_file")
        if [[ -n "$appid" ]]; then
            # Get game name
            game_name=$(grep -oP '^\s*"name"\s*"\K[^"]+' "$acf_file")
            echo "AppID: $appid, Game Name: $game_name"

            if [ ! -f "$poster_folder/$appid.png" ]; then
	            echo "Attempting to fetch poster by appid"
	            poster_url=$(get_poster "$appid")
	            if [[ -n "poster_url" ]]; then
	                curl -s "$poster_url" -o $poster_folder/"$appid"
                    if [ $? -eq 0 ]; then
                        convert $poster_folder/"$appid" -resize 600x900! -gravity South -fill white -undercolor '#00000080' -geometry +0-40 -pointsize 50 \
                            -background none -size 580x caption:"$game_name" \
                            -background none -alpha set -compose over -composite $poster_folder/"$appid".png
                        echo "Downloaded and processed poster from Steam API."
                        rm $poster_folder/"$appid"
	                    echo "Saved poster as $appid.png"
                    else
                        echo "Failed to download poster."
                    fi
	            fi 
            else
                echo "Poster already exists for $game_name"
                echo "Skipping download."
            fi

            game_run="/usr/bin/sunshine-run /usr/games/steam steam://rungameid/$appid"

            sunshine_entry=$(addEntry "$game_name" "$game_run" "$poster_folder/$appid.png")
            cat ${sunshine_conf:?} | jq '.apps += ['"${sunshine_entry}"']' > /tmp/sunshine.json
            mv -f /tmp/sunshine.json ${sunshine_conf:?}
        fi
    fi
done

echo "Sunshine configuration updated."
echo "Please Restart Sunshine to apply changes."
