#!/usr/bin/env bash
###
# File: configure-pcsx2.sh
# Project: scripts
# File Created: Friday, 25th August 2023 7:27:26 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 27th August 2023 8:09:57 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


# Generate PCSX2 Emulation directory structure
romsPath="/mnt/games/Emulation/roms"
biosPath="/mnt/games/Emulation/bios"
storagePath="/mnt/games/Emulation/storage"
mkdir -p \
    "${USER_HOME:?}"/.config/PCSX2 \
    "${biosPath:?}"/pcsx2/bios \
    "${storagePath:?}"/pcsx2/memcards

# Configure pcsx2 installation for Emulation directory structure
if [ ! -L "${USER_HOME:?}/.config/PCSX2/bios" ]; then
    [ -d "${USER_HOME:?}/.config/PCSX2/bios" ] && rm -rf "${USER_HOME:?}/.config/PCSX2/bios"
    ln -snf "${biosPath:?}/pcsx2/bios" "${USER_HOME:?}/.config/PCSX2/bios"
    echo "Place ps2 bios files here." > "${biosPath:?}/pcsx2/bios/placebioshere.txt"
fi
if [ ! -L "${USER_HOME:?}/.config/PCSX2/memcards" ]; then
    [ -d "${USER_HOME:?}/.config/PCSX2/memcards" ] && rm -rf "${USER_HOME:?}/.config/PCSX2/memcards"
    ln -snf "${storagePath:?}/pcsx2/memcards" "${USER_HOME:?}/.config/PCSX2/memcards"
fi

# Install default Duckstation config
