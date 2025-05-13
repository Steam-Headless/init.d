#!/usr/bin/env bash
###
# File: install-es-de.sh
# Project: scripts
# File Created: Wednesday, 23rd August 2023 7:16:02 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Tuesday, 13th May 2025 12:13:46 pm
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
#       $ ln -sf "./scripts/install-es-de.sh" "${USER_HOME:?}/init.d/install-es-de.sh"
#
###

set -euo pipefail

# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"

# Ensure this script is being executed as the default user
exec_script_as_default_user

# Config
package_name="EmulationStation-DE"
package_description="EmulationStation Desktop Edition (ES-DE) is a frontend for browsing and launching games from your multi-platform game collection."
package_icon_url="https://es-de.org/____impro/1/onewebmedia/ES-DE_logo.png?etag=%22621b-60428790%22&sourceContentType=image%2Fpng"
package_executable="${USER_HOME:?}/.local/bin/${package_name:?}.AppImage"
package_category="Game"
print_package_name

# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://gitlab.com/api/v4/projects/es-de%2Femulationstation-de/packages)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -c 'map(select(.name | contains("ES-DE_Stable")))' | jq -r '.[-1].version')
__latest_package_id=$(echo ${__registry_package_json:?} | jq -c 'map(select(.name | contains("ES-DE_Stable")))' | jq -r '.[-1].id')
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"

# Only install if the latest version does not already exist locally
if [ ! -f "${package_executable:?}" ] || [ ! -f "${USER_HOME:?}/.local/share/${package_name:?}/.installed-${package_name:?}-${__latest_package_version:?}" ]; then
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
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    mkdir -p "${USER_HOME:?}/.local/share/${package_name:?}"
    touch "${USER_HOME:?}/.local/share/${package_name:?}/.installed-${package_name:?}-${__latest_package_version:?}"
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi

# Generate EmulationStation directory structure
roms_path="/mnt/games/Emulation/roms"
tools_path="/mnt/games/Emulation/tools"
gamelists_path="/mnt/games/Emulation/gamelist"
downloaded_media_path="/mnt/games/Emulation/downloaded_media"
if [ -d "${USER_HOME:?}"/.emulationstation ]; then
    mv "${USER_HOME:?}"/.emulationstation "${USER_HOME:?}"/ES-DE
fi

mkdir -p \
    "${USER_HOME:?}"/ES-DE \
    "${roms_path:?}" \
    "${tools_path:?}" \
    "${downloaded_media_path:?}"

# Migrate gamelists path (this way we can use it with syncthing from a central location)
default_gamelist_path="${USER_HOME:?}/ES-DE/gamelists"
if [ -L "${default_gamelist_path:?}" ]; then
    echo "Symlink already exists at ${default_gamelist_path:?} — skipping."
elif [ -d "${gamelists_path:?}" ]; then
    echo "Destination exists at ${gamelists_path:?} — setting up symlink."
    if [[ -d "${default_gamelist_path:?}" ]]; then
        backup_path="${default_gamelist_path:?}-backup"
        echo "Existing directory found at ${default_gamelist_path:?} — backing it up to ${backup_path}"
        mv "${default_gamelist_path:?}" "${backup_path}"
        mkdir -p "${default_gamelist_path:?}"
    fi
    ln -s "${gamelists_path:?}" "${default_gamelist_path:?}"
else
    echo "Destination does not exist — attempting to move source..."
    if mv "${default_gamelist_path:?}" "${gamelists_path:?}"; then
        ln -s "${gamelists_path:?}" "${default_gamelist_path:?}"
    else
        echo -e "\e[1;31mERROR:\e[0m Failed to move ${default_gamelist_path:?} to ${gamelists_path:?}. Symlink not created."
    fi
fi

# Configure EmulationStation DE defaults
if [ ! -f "${USER_HOME:?}/ES-DE/settings/es_settings.xml" ]; then
    cat <<EOF >"${USER_HOME:?}/ES-DE/settings/es_settings.xml"
<?xml version="1.0"?>
<string name="MediaDirectory" value="${downloaded_media_path:?}" />
<string name="ROMDirectory" value="${roms_path:?}/" />
EOF
fi

# Configure Sunshine entry
print_step_header "Adding sunshine entry for ${package_name:?}"
ensure_sunshine_detached_command_entry "/usr/bin/sunshine-run ${package_executable:?}"

echo "DONE"
