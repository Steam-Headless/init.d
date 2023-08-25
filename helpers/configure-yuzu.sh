#!/usr/bin/env bash
###
# File: configure-yuzu.sh
# Project: scripts
# File Created: Friday, 25th August 2023 7:27:26 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 25th August 2023 7:29:48 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###


# Generate Yuzu Emulation directory structure
romsPath="/mnt/games/Emulation/roms"
biosPath="/mnt/games/Emulation/bios"
storagePath="/mnt/games/Emulation/storage"
mkdir -p \
    "${USER_HOME:?}"/.local/share/yuzu \
    "${biosPath:?}"/yuzu/keys \
    "${storagePath:?}"/yuzu/{dump,load,nand,screenshots,sdmc,tas}

# Configure yuzu installation for Emulation directory structure
if [ ! -L "${USER_HOME:?}/.local/share/yuzu/keys" ]; then
    [ -e "${USER_HOME:?}/.local/share/yuzu/keys" ] && unlink "${USER_HOME:?}/.local/share/yuzu/keys" 2>/dev/null
    ln -snf "${biosPath:?}/yuzu/keys" "${USER_HOME:?}/.local/share/yuzu/keys"
fi
if [ ! -L "${USER_HOME:?}/.local/share/yuzu/dump" ]; then
    [ -e "${USER_HOME:?}/.local/share/yuzu/dump" ] && unlink "${USER_HOME:?}/.local/share/yuzu/dump" 2>/dev/null
    ln -snf "${storagePath:?}/yuzu/dump" "${USER_HOME:?}/.local/share/yuzu/dump"
fi
if [ ! -L "${USER_HOME:?}/.local/share/yuzu/load" ]; then
    [ -e "${USER_HOME:?}/.local/share/yuzu/load" ] && unlink "${USER_HOME:?}/.local/share/yuzu/load" 2>/dev/null
    ln -snf "${storagePath:?}/yuzu/load" "${USER_HOME:?}/.local/share/yuzu/load"
fi
if [ ! -L "${USER_HOME:?}/.local/share/yuzu/nand" ]; then
    [ -e "${USER_HOME:?}/.local/share/yuzu/nand" ] && unlink "${USER_HOME:?}/.local/share/yuzu/nand" 2>/dev/null
    ln -snf "${storagePath:?}/yuzu/nand" "${USER_HOME:?}/.local/share/yuzu/nand"
fi
if [ ! -L "${USER_HOME:?}/.local/share/yuzu/screenshots" ]; then
    [ -e "${USER_HOME:?}/.local/share/yuzu/screenshots" ] && unlink "${USER_HOME:?}/.local/share/yuzu/screenshots" 2>/dev/null
    ln -snf "${storagePath:?}/yuzu/screenshots" "${USER_HOME:?}/.local/share/yuzu/screenshots"
fi
if [ ! -L "${USER_HOME:?}/.local/share/yuzu/sdmc" ]; then
    [ -e "${USER_HOME:?}/.local/share/yuzu/sdmc" ] && unlink "${USER_HOME:?}/.local/share/yuzu/sdmc" 2>/dev/null
    ln -snf "${storagePath:?}/yuzu/sdmc" "${USER_HOME:?}/.local/share/yuzu/sdmc"
fi
if [ ! -L "${USER_HOME:?}/.local/share/yuzu/tas" ]; then
    [ -e "${USER_HOME:?}/.local/share/yuzu/tas" ] && unlink "${USER_HOME:?}/.local/share/yuzu/tas" 2>/dev/null
    ln -snf "${storagePath:?}/yuzu/tas" "${USER_HOME:?}/.local/share/yuzu/tas"
fi

mkdir -p "${storagePath:?}/yuzu/nand/system/Contents/registered"
touch "${storagePath:?}/yuzu/nand/system/Contents/registered/putfirmwarehere.txt"
if [ ! -L "${biosPath}/yuzu/firmware" ]; then
    [ -e "${biosPath}/yuzu/firmware" ] && unlink "${biosPath}/yuzu/firmware" 2>/dev/null
    ln -snf "${storagePath:?}/yuzu/nand/system/Contents/registered" "${biosPath}/yuzu/firmware"
fi

# Configure EmulationStation DE
mkdir -p "${romsPath:?}/switch"
cat << 'EOF' > ${romsPath:?}/switch/systeminfo.txt
System name:
switch

Full system name:
Nintendo Switch

Supported file extensions:
.nca .NCA .nro .NRO .nso .NSO .nsp .NSP .xci .XCI .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_YUZU% -f -g %ROM%

Alternative launch command:
%EMULATOR_RYUJINX% %ROM%

Platform (for scraping):
switch

Theme folder:
switch
EOF
if ! grep -ri "switch:" "${romsPath:?}/systems.txt" &>/dev/null; then
    print_step_header "Adding 'switch' path to '${romsPath:?}/systems.txt'"
    echo "switch: " >> "${romsPath:?}/systems.txt"
    chown -R ${PUID:?}:${PGID:?} "${romsPath:?}/systems.txt"
fi
sed -i 's|^switch:.*$|switch: Nintendo Switch|' "${romsPath:?}/systems.txt"

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.local/share/yuzu \
    "${romsPath:?}/switch" \
    "${biosPath:?}"/yuzu \
    "${storagePath:?}"/yuzu
