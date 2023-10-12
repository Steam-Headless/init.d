games=()
steamgriddb_api="INSERTSTEAMGRIDDBAPIHERE"
sunshine_conf=${USER_HOME:?}/.config/sunshine/apps.json
poster_folder=${USER_HOME:?}/.local/share/posters

function getCoverArt {
    GAME_NAME="$1"

    # Encode the game name for URL
    GAME_NAME_ENCODED=$(printf %s "${GAME_NAME:?}" | jq -sRr @uri)

    # Make a GET request to the SteamGridDB API to search for the game by name
    RESPONSE=$(curl -H "Authorization: Bearer ${steamgriddb_api:?}" -s "https://www.steamgriddb.com/api/v2/search/autocomplete/$GAME_NAME_ENCODED")

    # Parse the JSON response to get the game ID
    GAME_ID=$(echo "$RESPONSE" | jq -r '.data[0].id')

    # Check if the game ID is valid
    if [ "$GAME_ID" == "null" ]; then
      echo "Game not found: $GAME_NAME"
      return 1
    fi

    # Make another GET request to the SteamGridDB API to get the poster art for the game by ID
    RESPONSE=$(curl -H "Authorization: Bearer ${steamgriddb_api:?}" -s "https://www.steamgriddb.com/api/v2/grids/game/$GAME_ID?dimensions=600x900")

    # Parse the JSON response to get the poster art URL
    POSTER_URL=$(echo "$RESPONSE" | jq -r '.data[0].url')

    # Check if the poster art URL is valid
    if [ "$POSTER_URL" == "null" ]; then
      echo "Poster art not found for game: $GAME_NAME"
      return 2
    fi

    # Download the poster art image from the URL
    curl -s -o "$GAME_NAME.jpg" "$POSTER_URL"

    # Resize the image to fit the  dimensions
    #convert "$GAME_NAME.jpg" -resize 300x450\! "$GAME_NAME.png"
    convert "$GAME_NAME.jpg" "$GAME_NAME.png"
    if [ -f "$GAME_NAME.jpg" ]; then
      rm "$GAME_NAME.jpg"
    fi
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

modus_operandi=$(zenity --list  --title "Choose Function" --radiolist  --column "Mode" --column="Name" 1 "Add" 2 "Remove" 3 "Exit")

case $modus_operandi in
  "Add")
    removeEntries
    if [ -d ${poster_folder:?} ]; then
      mkdir -p ${poster_folder:?}
    fi
    # Get all games and ids
    for manifest in /mnt/games/SteamLibrary/steamapps/appmanifest_*.acf; do
      appid=$(basename "$manifest" | cut -d_ -f2 | cut -d. -f1)
      name=$(grep -oP '"name"\s+"\K[^"]+' "$manifest")
      if grep -q -E "Proton|Runtime" <<< "$name"; then
        echo "Not importing "$name""
      else
        games+=("$appid $name")
      fi
    done
    # Add Entries
    (
    for game in "${!games[@]}"
      do
        echo "$((game * 100 / ${#games[@]}))"
        __game_name=$(echo ${games[$game]} | cut -d " " -f 2-)
        __game_name=${__game_name//\//}
        __game_name=${__game_name//\*/}
        __game_name=${__game_name//[^a-zA-Z0-9_\:\.\-\' ]/}
         if [ -z "${__game_name}" ]; then
           echo "Not adding "$(echo ${games[$game]} | cut -d " " -f 2-)" due to special characters"
           continue
         fi
      __game_id=$(echo ${games[$game]} | cut -d " " -f 1)
      __poster_path=${poster_folder:?}/"${__game_name:?}".png
      __game_run="/usr/bin/sunshine-run /usr/games/steam steam://rungameid/${__game_id:?}"

       if [ -f "${__poster_path:?}" ]; then
         echo "Found poster for ${__game_name:?}"
       else
         echo "Downloading Poster for ${__game_name:?}"
         getCoverArt "${__game_name:?}"
       fi
       if [ -f "${__game_name:?}".png ]; then
         mv "${__game_name:?}".png ${USER_HOME:?}/.local/share/posters/
         sunshine_entry=$(addEntry "${__game_name:?}" "${__game_run:?}" "${__poster_path:?}")
       else
         sunshine_entry=$(addEntry "${__game_name:?}" "${__game_run:?}")
       fi
       
       cat ${sunshine_conf:?} | jq '.apps += ['"${sunshine_entry}"']' > /tmp/sunshine.json
       mv -f /tmp/sunshine.json ${sunshine_conf:?}
    done
    echo "100"
    ) | zenity --progress --title="Adding Entries" --text="Importing" --auto-close
    # Remove the above zenity section for terminal output and debugging
    zenity --info --title="Adding" --text="Done";;
  "Remove")
    removeEntries
    zenity --info --title="Removing" --text="Succesfully removed All added entries";;
  *)
    zenity --info --title="Exiting" --text="Exit Application";;
esac