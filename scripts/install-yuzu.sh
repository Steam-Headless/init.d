#!/usr/bin/env bash
###
# File: install-yuzu.sh
# Project: scripts
# File Created: Wednesday, 23rd August 2023 7:16:02 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Wednesday, 25th October 2023 2:56:30 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install Yuzu during container startup.
#   This will also configure Yuzu with some default options for Steam Headless.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/install-yuzu.sh" "${USER_HOME:?}/init.d/install-yuzu.sh"
#
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


# Config
package_name="Yuzu"
package_description="Nintendo Switch Emulator"
package_icon_url="https://raw.githubusercontent.com/yuzu-emu/yuzu-assets/master/icons/icon.png"
package_executable="${USER_HOME:?}/Applications/${package_name,,}.AppImage"
package_category="Game"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/yuzu-emu/yuzu-mainline/releases/latest)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.name' | cut -d "-" -f 3 | cut -d "." -f 1)
__latest_package_id=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.id')
__latest_package_url=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.browser_download_url')
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"
__installed_version=$(catalog -g ${package_name,,})


# Only install if the latest version does not already exist locally
if ([ ! -f "${package_executable:?}" ] || [ "${__installed_version:-X}" != "${__latest_package_version:?}" ]); then
    # Download Appimage to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    fetch_appimage_and_make_executable "${__latest_package_url:?}"

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu short is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    catalog -s ${package_name,,} ${__latest_package_version:?}
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi

source "${USER_HOME:?}/init.d/helpers/configure-yuzu.sh"

echo "DONE"
