#!/usr/bin/env bash
###
# File: es_steam_import.sh
# Project: scripts
# File Created: Monday, 11th September 2023 3:57:47 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Saturday, 16th September 2023 10:17:17 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Create XDG Desktop shortcuts for all detected steam games at default path.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/es_steam_import.sh" "${USER_HOME:?}/init.d/es_steam_import.sh"
#
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user

function CreateXDGDesktopShorcut() {
    __steam_id="$1"
    __steam_name="$2"

    cat <<EOF
[Desktop Entry]
Name=${__steam_name:?}
Coment=Steam Shortcut
Exec=steam steam://rungameid/${__steam_id:?}
Icon=steam_icon_${__steam_id:?}
Terminal=false
Type=Application
Categories=Game;
EOF
}

romsPath="/mnt/games/Emulation/roms/steam"
steamPaths=$(cat "${USER_HOME:?}/.steam/steam/steamapps/libraryfolders.vdf" | grep "path" | awk -F"\"" '{print $4}')

if [[ -d "${romsPath:?}" ]]; then
    rm -r "${romsPath:?}"
fi
mkdir -p "${romsPath:?}"

for steamPath in ${steamPaths}; do
    if [[ "${steamPath:?}" == *"${USER_HOME:?}"* ]]; then
        echo "Ignoring steam library '${steamPath:?}'"
        continue
    fi
    echo "Parsing steam library '${steamPath:?}'"
    __steamapps=$(ls "${steamPath:?}/steamapps/" | grep ".acf")

    for __steamapp in ${__steamapps:?}; do
        steam_id=$(grep "appid" "${steamPath:?}/steamapps/${__steamapp}" | cut -d '"' -f 4)
        steam_name_dirty=$(grep "name" "${steamPath:?}/steamapps/${__steamapp}" | cut -d '"' -f 4)
        steam_name=$(echo "${steam_name_dirty:?}" | sed -e 's/"//g')
        print_step_header "Found steam app '${steam_name_dirty:?}'"
        if [[ ! -z ${steam_name:?} ]]; then
            print_step_header "Creating shortcut for steam app '${steam_name_dirty:?}'"
            es_entry="${romsPath:?}/$(echo ${steam_name:?} | sed -e 's#/#_#g').desktop"
            es_shortcut=$(CreateXDGDesktopShorcut ${steam_id:?} ${steam_name:?})

            echo "${es_shortcut:?}" > "${es_entry:?}"
        else
            print_step_header "Shortcut for steam app '${steam_name_dirty:?}' already exists"
        fi
    done
done
