#!/usr/bin/env bash
###
# File: configure-duckstation.sh
# Project: scripts
# File Created: Friday, 25th August 2023 7:27:26 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 27th August 2023 8:09:57 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


# Generate Yuzu Emulation directory structure
romsPath="/mnt/games/Emulation/roms"
biosPath="/mnt/games/Emulation/bios"
storagePath="/mnt/games/Emulation/storage"
mkdir -p \
    "${USER_HOME:?}"/.local/share/duckstation \
    "${biosPath:?}"/duckstation/bios \
    "${storagePath:?}"/duckstation/memcards

# Configure duckstation installation for Emulation directory structure
if [ ! -L "${USER_HOME:?}/.local/share/duckstation/bios" ]; then
    [ -d "${USER_HOME:?}/.local/share/duckstation/bios" ] && rm -rf "${USER_HOME:?}/.local/share/duckstation/bios"
    ln -snf "${biosPath:?}/duckstation/bios" "${USER_HOME:?}/.local/share/duckstation/bios"
    echo "Place psx bios files here." > "${biosPath:?}/duckstation/bios/readme.txt"
fi
if [ ! -L "${USER_HOME:?}/.local/share/duckstation/memcards" ]; then
    [ -d "${USER_HOME:?}/.local/share/duckstation/memcards" ] && rm -rf "${USER_HOME:?}/.local/share/duckstation/memcards"
    ln -snf "${storagePath:?}/duckstation/memcards" "${USER_HOME:?}/.local/share/duckstation/memcards"
fi

# Install default Duckstation config
