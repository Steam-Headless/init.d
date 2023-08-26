#!/usr/bin/env bash
###
# File: install-mgba.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 27th August 2023 10:47:27 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


# Config
package_name="mGBA"
package_description="Gameboy Advance Emulator"
package_icon_url="https://raw.githubusercontent.com/mgba-emu/mgba/master/res/mgba-512.png"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"
package_icon="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"


[ -f "${USER_HOME:?}/init.d/helpers/setup-directories.sh" ] && source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
[ -f "${USER_HOME:?}/init.d/helpers/functions.sh" ] && source "${USER_HOME:?}/init.d/helpers/functions.sh"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/mgba-emu/mgba/releases/latest)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.tag_name')
__latest_package_id=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.id')
__latest_package_url=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.browser_download_url')
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"


# Only install if the latest version does not already exist locally
if [ ! -f "${package_executable:?}" ] || [ ! -f "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}" ]; then
    # Download Appimage to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    fetch_appimage_and_make_executable "${__latest_package_url:?}"

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu short is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    touch "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}"
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi

echo "DONE"
