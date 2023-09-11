#!/usr/bin/env bash
###
# File: install-wiiu-downloader.sh
# Project: scripts
# File Created: Sunday, 3rd September 2023 10:21:43 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 11th September 2023 4:14:29 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install WiiUDownloader during container startup.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/install-wiiu-downloader.sh" "${USER_HOME:?}/init.d/install-wiiu-downloader.sh"
#
###


# Config
package_name="WiiUDownloader"
package_description="WiiUDownloader is a Golang program that allows you to download Wii U games from Nintendo's servers."
package_icon_url="https://www.clipartmax.com/png/middle/108-1081687_playstation-3-wii-u-wii-u-logo-png.png"
package_executable="${USER_HOME:?}/.local/share/${package_name:?}/${package_name:?}.AppImage"
package_category="Utility"


source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
source "${USER_HOME:?}/init.d/helpers/functions.sh"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/Xpl0itU/WiiUDownloader/releases | jq 'sort_by(.published_at) | .[-1]')
__latest_package_version=$(echo "${__registry_package_json:?}" | jq -r '.tag_name')
__latest_package_id=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith(".AppImage")) | .id' | head -n 1)
__latest_package_url=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith(".AppImage")) | .browser_download_url' | head -n 1)
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"


# Only install if the latest version does not already exist locally
mkdir -p "${USER_HOME:?}/.local/share/${package_name:?}"
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
set_default_user_ownership "${USER_HOME:?}/.local/share/${package_name:?}"

echo "DONE"
