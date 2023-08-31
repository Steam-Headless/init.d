#!/usr/bin/env bash
###
# File: install-citra.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 27th August 2023 10:52:09 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install Citra during container startup.
#   This will also configure citra with some default options for Steam Headless.
#   It will also configure the citra AppImage as the default emulator for 3DS ROMs in ES-DE.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "${USER_HOME:?}/init.d/scripts/install-citra.sh" "${USER_HOME:?}/init.d/install-citra.sh"
#
###


# Config
package_name="citra-canary"
package_description="3DS Emulator"
package_icon_url="https://cdn2.steamgriddb.com/file/sgdb-cdn/icon/075b24b68eb3cb44b3fa4e331d86db89.png"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"
package_icon="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"


source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
source "${USER_HOME:?}/init.d/helpers/functions.sh"
source "${USER_HOME:?}/init.d/helpers/functions-es-de-config.sh"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/citra-emu/citra-canary/releases/latest)
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


# Generate duckstation Emulation directory structure
__emulation_path="/mnt/games/Emulation"
mkdir -p \
    "${USER_HOME:?}"/.local/share/duckstation \
    "${__emulation_path:?}"/roms/n3ds \
    "${__emulation_path:?}"/storage/citra/{nand,sdmc,states,keys,sysdata} 

# Generate a default config if missing
if [ ! -f "${USER_HOME:?}/.local/share/duckstation/settings.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.local/share/duckstation/settings.ini"
EOF
fi

# Configure EmulationStation DE
cat << 'EOF' > "${__emulation_path:?}/roms/n3ds/systeminfo.txt"
System name:
n3ds

Full system name:
Nintendo 3DS

Supported file extensions:
.3ds .3DS .3dsx .3DSX .app .APP .axf .AXF .cci .CCI .cxi .CXI .elf .ELF .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_CITRA% %ROM%

Alternative launch commands:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/citra_libretro.so %ROM%
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/citra2018_libretro.so %ROM%

Platform (for scraping):
n3ds

Theme folder:
n3ds
EOF
if ! grep -ri "psx:" "${__emulation_path:?}/roms/systems.txt" &>/dev/null; then
    print_step_header "Adding 'n3ds' path to '${__emulation_path:?}/roms/systems.txt'"
    echo "n3ds: " >> "${__emulation_path:?}/roms/systems.txt"
    chown -R ${PUID:?}:${PGID:?} "${__emulation_path:?}/roms/systems.txt"
fi
sed -i 's|^n3ds:.*$|n3ds: Nintendo 3DS|' "${__emulation_path:?}/roms/systems.txt"
ensure_esde_alternative_emulator_configured "n3ds" "Citra (Standalone)"

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.local/share/duckstation \
    "${__emulation_path:?}"/roms/n3ds \
    "${__emulation_path:?}"/storage/citra

echo "DONE"
