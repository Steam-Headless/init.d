#!/usr/bin/env bash
###
# File: install-es-de.sh
# Project: scripts
# File Created: Wednesday, 23rd August 2023 7:16:02 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Saturday, 26th August 2023 11:53:37 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install EmulationStation-DE during container startup.
#   This will also configure EmulationStation-DE with some default options for Steam Headless.
#   It will also configure an entry into Sunshine's apps.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "${USER_HOME:?}/init.d/scripts/install-es-de.sh" "${USER_HOME:?}/init.d/install-es-de.sh"
#
###


# Config
package_name="EmulationStation-DE"
package_description="EmulationStation Desktop Edition (ES-DE) is a frontend for browsing and launching games from your multi-platform game collection."
package_icon_url="https://es-de.org/____impro/1/onewebmedia/ES-DE_logo.png?etag=%22621b-60428790%22&sourceContentType=image%2Fpng"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"
package_icon="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"


[[ -f "${USER_HOME:?}/init.d/helpers/setup-directories.sh" ]] && source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
[[ -f "${USER_HOME:?}/init.d/helpers/functions.sh" ]] && source "${USER_HOME:?}/init.d/helpers/functions.sh"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://gitlab.com/api/v4/projects/es-de%2Femulationstation-de/packages)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -c 'map(select(.name | contains("ES-DE_Stable")))' | jq -r '.[-1].version')
__latest_package_id=$(echo ${__registry_package_json:?} | jq -c 'map(select(.name | contains("ES-DE_Stable")))' | jq -r '.[-1].id')
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"


# Only install if the latest version does not already exist locally
if [[ ! -f "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}" ]]; then
    # Fetch download links
    print_step_header "Fetching download link for ${package_name:?} version ${__latest_package_version:?}"
    __latest_package_files_json=$(wget -O - -o /dev/null https://gitlab.com/api/v4/projects/es-de%2Femulationstation-de/packages/${__latest_package_id:?}/package_files)
    __latest_package_file_id=$(echo ${__latest_package_files_json:?} | jq -c 'map(select(.file_name | contains("x64.AppImage")))' | jq -r '.[-1].id')
    __latest_package_file_sha256=$(echo ${__latest_package_files_json:?} | jq -c 'map(select(.file_name | contains("x64.AppImage")))' | jq -r '.[-1].file_sha256')

    # Download Appimage to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    fetch_appimage_and_make_executable "https://gitlab.com/es-de/emulationstation-de/-/package_files/${__latest_package_file_id:?}/download"

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu short is present for ${package_name:?}"
    ensure_menu_shortcut

    # Mark this version as installed
    touch "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}"
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi


# Generate EmulationStation directory structure
romsPath="/mnt/games/Emulation/roms"
toolsPath="/mnt/games/Emulation/tools"
mkdir -p \
    "${USER_HOME:?}"/.emulationstation \
    "${romsPath:?}" \
    "${toolsPath:?}"/downloaded_media

# Configure EmulationStation DE defaults
if [ ! -f "${USER_HOME:?}/.emulationstation/es_settings.xml" ]; then
    cat << 'EOF' > "${USER_HOME:?}/.emulationstation/es_settings.xml"
<?xml version="1.0"?>
<string name="MediaDirectory" value="/mnt/games/Emulation/tools/downloaded_media" />
<string name="ROMDirectory" value="/mnt/games/Emulation/roms/" />
<string name="ScreensaverSlideshowImageDir" value="~/.emulationstation/slideshow/custom_images" />
EOF
fi

# Configure Sunshine entry
print_step_header "Adding sunshine entry for ${package_name:?}"
ensure_sunshine_entry "flatpak-spawn --host /usr/bin/sunshine-run /home/default/Applications/EmulationStation-DE-x64.AppImage"
