#!/usr/bin/env bash
###
# File: install-heroic.sh
# Project: scripts
# File Created: Wednesday, 6th September 2023 1:42:38 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Wednesday, 6th September 2023 2:29:38 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


# Config
package_name="Heroic"
package_description="Heroic Games Launcher is an Open Source GOG and Epic games launcher."
package_icon_url="https://heroicgameslauncher.com/_next/static/images/logo-29caca3fc66e11655d58060009610568.png"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"


source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
source "${USER_HOME:?}/init.d/helpers/functions.sh"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.tag_name')
__latest_package_id=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith(".AppImage")) | .id' | head -n 1)
__latest_package_url=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith(".AppImage")) | .browser_download_url' | head -n 1)
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"


# Only install if the latest version does not already exist locally
if [ ! -f "${package_executable:?}" ] || [ ! -f "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}" ]; then
    # Download Appimage to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    fetch_appimage_and_make_executable "${__latest_package_url:?}"

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu shortcut is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    touch "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}"
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi


# Create a Heroic games library directory
__heroic_game_library_path="/mnt/games/GameLibrary/Heroic"
if [ -d "${__heroic_game_library_path:?}" ]; then
    mkdir -p \
        "${__heroic_game_library_path:?}"/Prefixes
    chown -R ${PUID:?}:${PGID:?} ${__heroic_game_library_path:?}
    chown ${PUID:?}:${PGID:?} /mnt/games/GameLibrary
fi

# Install default Ryujinx config
mkdir -p "${USER_HOME:?}"/.config/heroic/store 
if [ ! -f "${USER_HOME:?}/.config/heroic/config.json" ]; then
    cat << EOF > "${USER_HOME:?}/.config/heroic/config.json"
{
  "defaultSettings": {
    "checkUpdatesInterval": 10,
    "enableUpdates": false,
    "addDesktopShortcuts": false,
    "addStartMenuShortcuts": false,
    "autoInstallDxvk": true,
    "autoInstallVkd3d": true,
    "addSteamShortcuts": true,
    "preferSystemLibs": false,
    "checkForUpdatesOnStartup": false,
    "autoUpdateGames": false,
    "customWinePaths": [],
    "defaultInstallPath": "${__heroic_game_library_path:?}",
    "libraryTopSection": "disabled",
    "defaultSteamPath": "${USER_HOME:?}/.steam/steam",
    "defaultWinePrefix": "${__heroic_game_library_path:?}/Prefixes",
    "hideChangelogsOnStartup": false,
    "language": "en",
    "maxWorkers": 0,
    "minimizeOnLaunch": false,
    "nvidiaPrime": false,
    "enviromentOptions": [],
    "wrapperOptions": [],
    "showFps": false,
    "useGameMode": false,
    "userInfo": {
      "name": "default"
    },
    "wineCrossoverBottle": "Heroic",
    "winePrefix": "${__heroic_game_library_path:?}/Prefixes",
    "wineVersion": {
      "bin": "${USER_HOME:?}/.config/heroic/tools/wine/Wine-GE-latest/bin/wine",
      "name": "Wine - Wine-GE-latest",
      "type": "wine",
      "lib": "${USER_HOME:?}/.config/heroic/tools/wine/Wine-GE-latest/lib64",
      "lib32": "${USER_HOME:?}/.config/heroic/tools/wine/Wine-GE-latest/lib",
      "wineserver": ""
    },
    "enableEsync": true,
    "enableFsync": true,
    "exitToTray": false,
    "startInTray": false,
    "darkTrayIcon": false,
    "useSteamRuntime": false
  },
  "version": "v0"
}
EOF
fi

# Configure Sunshine entry
print_step_header "Adding sunshine entry for ${package_name:?}"
ensure_sunshine_detached_command_entry "/usr/bin/sunshine-run ${package_executable:?}"

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.config/heroic 

echo "DONE"
