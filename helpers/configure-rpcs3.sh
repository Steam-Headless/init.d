#!/usr/bin/env bash
###
# File: configure-rpcs3.sh
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
    "${USER_HOME:?}"/.config/rpcs3 \
    "${storagePath:?}"/rpcs3/home}

# Configure yuzu installation for Emulation directory structure
if [ ! -L "${USER_HOME:?}/.config/rpcs3/dev_hdd0/home" ]; then
    [ -d "${USER_HOME:?}/.config/rpcs3/dev_hdd0/home" ] && rm -rf "${USER_HOME:?}/.config/rpcs3/dev_hdd0/home"
    ln -snf "${storagePath:?}/rpcs3/home" "${USER_HOME:?}/.config/rpcs3/dev_hdd0/home"
fi
touch "${storagePath:?}/rpcs3/profilesavedatawithin.txt"
