#!/usr/bin/env bash
###
# File: install-xemu.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 3:53:57 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 28th August 2023 12:23:14 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###


# Config
package_name="xemu"
package_description="A free and open-source application that emulates the original Microsoft Xbox game console, enabling people to play their original Xbox games on Windows, macOS, and Linux systems."
package_icon_url="https://cdn2.steamgriddb.com/file/sgdb-cdn/logo_thumb/8f6240dce8bc1548c3f66bc5ed17369f.png"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"
package_icon="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"


source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
source "${USER_HOME:?}/init.d/helpers/functions.sh"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/xemu-project/xemu/releases/latest)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.tag_name')
__latest_package_id=$(echo ${__registry_package_json:?} | jq -r '[ .assets[] | select(.name | endswith(".AppImage")) ]' | jq -r '.[] | select(.name | contains("dbg") | not)' | jq -r '.id')
__latest_package_url=$(echo ${__registry_package_json:?} | jq -r '[ .assets[] | select(.name | endswith(".AppImage")) ]' | jq -r '.[] | select(.name | contains("dbg") | not)' | jq -r '.browser_download_url')
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

# Generate Emulation directory structure
romsPath="/mnt/games/Emulation/roms"
biosPath="/mnt/games/Emulation/bios"
savesPath="/mnt/games/Emulation/saves"
storagePath="/mnt/games/Emulation/storage"
mkdir -p \
    "${USER_HOME:?}"/.local/share/xemu/xemu \
    "${romsPath:?}/xbox" \
    "${biosPath:?}/xemu" \
    "${savesPath:?}"/xemu \
    "${storagePath:?}"/xemu

# Install missing bios
if [ ! -f "${storagePath:?}/xemu/eeprom.bin" ]; then
    print_step_header "Fetching eeprom.bin"
    __xbox_bios_url="https://github.com/dragoonDorise/EmuDeck/raw/dbfe2d6e7cf4123ff4b537ff75ddcbeea7860b2b/configs/app.xemu.xemu/data/xemu/xemu/eeprom.bin"
    wget -O "${storagePath:?}/xemu/eeprom.bin" \
        --quiet -o /dev/null \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        "${__xbox_bios_url:?}"
fi

# Install missing Xbox HDD
if [ ! -f "${storagePath:?}/xemu/xbox_hdd.qcow2" ]; then
    print_step_header "Fetching xbox_hdd.qcow2"
    wget -O "${storagePath:?}/xemu/xbox_hdd.qcow2.zip" \
        --quiet -o /dev/null \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        "https://github.com/mborgerson/xemu-hdd-image/releases/latest/download/xbox_hdd.qcow2.zip"
    
    print_step_header "Extracting xbox_hdd.qcow2"
    pushd "${storagePath:?}/xemu" &> /dev/null || (echo "Error: Unable to change directory before extracting Xbox HDD." && exit 1)
        unzip -j xbox_hdd.qcow2.zip
        rm -rf xbox_hdd.qcow2.zip
    popd &> /dev/null || exit 1
fi

# Install default xemu config
if [ ! -f "${USER_HOME:?}/.local/share/xemu/xemu/xemu.toml" ]; then
    cat << EOF > "${USER_HOME:?}/.local/share/xemu/xemu/xemu.toml"
[general]
show_welcome = false

[general.misc]
skip_boot_anim = true

[input.bindings]
port1 = '03000000de280000ff11000001000000'

[display.ui]
fit = 'stretch'

[sys]
mem_limit = '128'

[sys.files]
bootrom_path = '${biosPath:?}/xemu/mcpx_1.0.bin'
flashrom_path = '${biosPath:?}/xemu/Complex_4627v1.03.bin'
eeprom_path = '${storagePath:?}/xemu/eeprom.bin'
hdd_path = '${storagePath:?}/xemu/xbox_hdd.qcow2'

EOF
fi

# Configure EmulationStation DE
cat << 'EOF' > "${romsPath:?}/xbox/systeminfo.txt"
System name:
xbox

Full system name:
Microsoft Xbox

Supported file extensions:
.iso .ISO

Launch command:
%EMULATOR_XEMU% -dvd_path %ROM%

Platform (for scraping):
xbox

Theme folder:
xbox
EOF
if ! grep -ri "xbox:" "${romsPath:?}/systems.txt" &>/dev/null; then
    print_step_header "Adding 'xbox' path to '${romsPath:?}/systems.txt'"
    echo "xbox: " >> "${romsPath:?}/systems.txt"
    chown -R ${PUID:?}:${PGID:?} "${romsPath:?}/systems.txt"
fi
sed -i 's|^xbox:.*$|xbox: Microsoft Xbox|' "${romsPath:?}/systems.txt"

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.local/share/xemu/xemu \
    "${savesPath:?}"/xemu \
    "${storagePath:?}"/xemu \
    "${romsPath:?}/xbox"

echo "DONE"
