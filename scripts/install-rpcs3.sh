#!/usr/bin/env bash
###
# File: install-rpcs3.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 27th August 2023 10:52:09 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


# Config
package_name="rpcs3"
package_description="Sony Playstation 3 Emulator"
package_icon_url="https://cdn2.steamgriddb.com/file/sgdb-cdn/icon/add5aebfcb33a2206b6497d53bc4f309/32/24x24.png"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"
package_icon="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"


source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
source "${USER_HOME:?}/init.d/helpers/functions.sh"
source "${USER_HOME:?}/init.d/helpers/functions-es-de-config.sh"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/RPCS3/rpcs3-binaries-linux/releases/latest)
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

# Generate rpcs3 Emulation directory structure
__emulation_path="/mnt/games/Emulation"
mkdir -p \
    "${USER_HOME:?}"/.config/rpcs3/dev_hdd0/home \
    "${__emulation_path:?}"/storage/rpcs3/{home,savestates,patches} \
    "${__emulation_path:?}"/roms/ps3

ensure_symlink "${__emulation_path:?}/storage/rpcs3/home" "${USER_HOME:?}/.config/rpcs3/dev_hdd0/home"
ensure_symlink "${__emulation_path:?}/storage/rpcs3/savestates" "${USER_HOME:?}/.config/rpcs3/savestates"
ensure_symlink "${__emulation_path:?}/storage/rpcs3/patches" "${USER_HOME:?}/.config/rpcs3/patches"


# Generate a default config if missing
#if [ ! -f "${USER_HOME:?}/.config/rpcs3/config.yml" ]; then
#    cat << EOF > "${USER_HOME:?}/.config/rpcs3/config.yml"
#
#EOF
#fi

# Configure EmulationStation DE
cat << 'EOF' > "${__emulation_path:?}/roms/ps3/systeminfo.txt"
System name:
ps3

Full system name:
Sony Playstation 3

Supported file extensions:
.desktop .ps3 .PS3 .ps3dir .PS3DIR

Launch command:
%EMULATOR_RPCS3% --no-gui %ROM%

Alternative launch commands:

Platform (for scraping):
ps3

Theme folder:
ps3
EOF
if ! grep -ri "ps3:" "${__emulation_path:?}/roms/systems.txt" &>/dev/null; then
    print_step_header "Adding 'ps3' path to '${__emulation_path:?}/roms/systems.txt'"
    echo "ps3: " >> "${__emulation_path:?}/roms/systems.txt"
    chown -R ${PUID:?}:${PGID:?} "${__emulation_path:?}/roms/systems.txt"
fi
sed -i 's|^ps3:.*$|ps3: Sony Playstation 3|' "${__emulation_path:?}/roms/systems.txt"
ensure_esde_alternative_emulator_configured "ps3" "RPCS3 Directory (Standalone)"

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.config/rpcs3 \
    "${__emulation_path:?}"/storage/rpcs3 \
    "${__emulation_path:?}"/roms/ps3

echo "DONE"
