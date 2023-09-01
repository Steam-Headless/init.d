#!/usr/bin/env bash
###
# File: install-cemu.sh
# Project: scripts
# File Created: Saturday, 2nd September 2023 11:08:22 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Saturday, 2nd September 2023 11:22:11 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


# Config
package_name="Cemu"
package_description="Nintendo Wii U Emulator"
package_icon_url="https://upload.wikimedia.org/wikipedia/commons/2/25/Cemu_Emulator_icon.png"
package_executable="${USER_HOME:?}/Applications/${package_name,,}.AppImage"
package_category="Game"
package_icon="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"


source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
source "${USER_HOME:?}/init.d/helpers/functions.sh"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/cemu-project/Cemu/releases | jq 'sort_by(.published_at) | .[-1]')
__latest_package_version=$(echo "${__registry_package_json:?}" | jq -r '.tag_name')
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


echo "DONE"
