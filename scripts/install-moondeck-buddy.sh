#!/usr/bin/env bash
###
# File: install-moondeck-buddy.sh
# Project: scripts
# File Created: Monday, 11th September 2023 3:57:47 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 17th September 2023 4:24:09 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install MoonDeckBuddy during container startup.
#   This will also configure MoonDeckBuddy with some default options for Steam Headless.
#   It will also configure an entry into Sunshine's apps.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/install-moondeck-buddy.sh" "${USER_HOME:?}/init.d/install-moondeck-buddy.sh"
#
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


# Config
package_name="MoonDeckBuddy"
package_description="The server-side component of MoonDeck - a plugin that makes it easier to manage your gamestream sessions from the SteamDeck."
package_icon_url="https://raw.githubusercontent.com/FrogTheFrog/moondeck-buddy/main/resources/icons/app-256.png"
package_executable="${USER_HOME:?}/.local/share/${package_name:?}/${package_name:?}.AppImage"
package_category="Utility"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/FrogTheFrog/moondeck-buddy/releases/latest)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.tag_name')
__latest_package_id=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith(".AppImage")) | .id' | head -n 1)
__latest_package_url=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith(".AppImage")) | .browser_download_url' | head -n 1)
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"


# Only install if the latest version does not already exist locally
mkdir -p "${USER_HOME:?}/.local/share/${package_name:?}"
if ([ ! -f "${package_executable:?}" ] || [ ! -f "/tmp/.user-script-${package_name,,}-installed" ]); then
    # Download Appimage to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    fetch_appimage_and_make_executable "${__latest_package_url:?}"

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu shortcut is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    touch "/tmp/.user-script-${package_name,,}-installed"
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi


# Configure default settings
if [ ! -f "${USER_HOME:?}/.config/moondeckbuddy/settings.json" ]; then
    cat << EOF > "${USER_HOME:?}/.config/moondeckbuddy/settings.json"
{
    "force_big_picture": false,
    "handled_displays": [
    ],
    "logging_rules": "",
    "nvidia_reset_mouse_acceleration_after_stream_end_hack": false,
    "port": 59999,
    "prefer_hibernation": false,
    "ssl_protocol": "SecureProtocols",
    "sunshine_apps_filepath": "${USER_HOME:?}/.config/sunshine/apps.json"
}
EOF
fi

# Always launch application on startup
cat << EOF > "${USER_HOME:?}/.config/autostart/moondeckbuddy.desktop"
[Desktop Entry]
Type=Application
Name=MoonDeckBuddy
Exec=${package_executable:?}
Icon=MoonDeckBuddy
EOF

# Configure Sunshine entry
package_name="MoonDeckStream"   # Note the change in package name when executed from Moonlight
print_step_header "Adding sunshine entry for ${package_name:?}"
ensure_sunshine_command_entry "/usr/bin/sunshine-run ${package_executable:?} --exec MoonDeckStream"

echo "DONE"
