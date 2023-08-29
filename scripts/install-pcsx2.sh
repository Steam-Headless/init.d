#!/usr/bin/env bash
###
# File: install-pcsx2.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 27th August 2023 10:52:09 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install PCSX2 during container startup.
#   This will also configure PCSX2 with some default options for Steam Headless.
#   It will also configure the PCSX2 AppImage as the default emulator for PS2 ROMs in ES-DE.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "${USER_HOME:?}/init.d/scripts/install-pcsx2.sh" "${USER_HOME:?}/init.d/install-pcsx2.sh"
#
#   IMPORTANT: Please run PCSX2 once and select to import pre-existing config
#
###


# Config
package_name="pcsx2"
package_description="Sony Playstation 2 Emulator"
package_icon_url="https://cdn2.steamgriddb.com/file/sgdb-cdn/icon/9a32ff36c65e8ba30915a21b7bd76506/32/24x24.png"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"
package_icon="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"


source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
source "${USER_HOME:?}/init.d/helpers/functions.sh"
source "${USER_HOME:?}/init.d/helpers/functions-es-de-config.sh"
print_package_name

# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/PCSX2/pcsx2/releases/latest)
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
romsPath="/mnt/games/Emulation/roms"
biosPath="/mnt/games/Emulation/bios"
savesPath="/mnt/games/Emulation/saves"
storagePath="/mnt/games/Emulation/storage"
mkdir -p \
    "${USER_HOME:?}"/.config/PCSX2/inis \
    "${savesPath:?}"/pcsx2/memcards \
    "${savesPath:?}"/pcsx2/sstates \
    "${biosPath:?}"/pcsx2 \
    "${storagePath:?}"/pcsx2/snaps \
    "${storagePath:?}"/pcsx2/cheats \
    "${romsPath:?}"/ps2

# Generate a default config if missing
# Currently need to run PCSX2 once to import the config, can't figure out how to bypass it
if [ ! -f "${USER_HOME:?}/.config/PCSX2/inis/OnePAD2.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.config/PCSX2/inis/OnePAD2.ini"
first_time_wizard = 0
log = 0
options = 0
mouse_sensibility = 100
ff_intensity = 32767
uid[0] = 0
uid[1] = 0
EOF
fi
if [ ! -f "${USER_HOME:?}/.config/PCSX2/inis/PCSX2_vm.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.config/PCSX2/inis/PCSX2_vm.ini"
[EmuCore]
CdvdVerboseReads=disabled
CdvdDumpBlocks=disabled
CdvdShareWrite=disabled
EnablePatches=enabled
EnableCheats=disabled
EnableWideScreenPatches=true
ConsoleToStdio=disabled
HostFs=disabled
BackupSavestate=enabled
McdEnableEjection=enabled
McdFolderAutoManage=enabled
MultitapPort0_Enabled=disabled
MultitapPort1_Enabled=disabled
EOF
fi
if [ ! -f "${USER_HOME:?}/.config/PCSX2/inis/GSdx.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.config/PCSX2/inis/GSdx.ini"
UserHacks = 1
UserHacks_AutoFlush = 0
UserHacks_CPU_FB_Conversion = 0
UserHacks_DisableDepthSupport = 0
UserHacks_DisablePartialInvalidation = 0
UserHacks_Disable_Safe_Features = 0
UserHacks_HalfPixelOffset = 1
UserHacks_Half_Bottom_Override = -1
UserHacks_SkipDraw = 0
UserHacks_SkipDraw_Offset = 0
UserHacks_TCOffsetX = 0
UserHacks_TCOffsetY = 0
UserHacks_TriFilter = 0
UserHacks_WildHack = 0
UserHacks_align_sprite_X = 1
UserHacks_merge_pp_sprite = 1
UserHacks_round_sprite_offset = 0
shaderfx = 0
shaderfx_conf = shaders/GSdx_FX_Settings.ini
shaderfx_glsl = shaders/GSdx.fx
upscale_multiplier = 3
wrap_gs_mem = 0
EOF
fi
if [ ! -f "${USER_HOME:?}/.config/PCSX2/inis/PCSX2_ui.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.config/PCSX2/inis/PCSX2_ui.ini"
[Folders]
UseDefaultBios=disabled
UseDefaultSnapshots=disabled
UseDefaultSavestates=disabled
UseDefaultMemoryCards=disabled
UseDefaultLogs=enabled
UseDefaultLangs=enabled
UseDefaultPluginsFolder=enabled
UseDefaultCheats=disabled
UseDefaultCheatsWS=enabled
Bios=${biosPath:?}/pcsx2
Snapshots=${storagePath:?}/pcsx2/snaps
Savestates=${savesPath:?}/pcsx2/sstates
MemoryCards=${savesPath:?}/pcsx2/memcards
Logs=/home/default/.config/PCSX2/logs
Langs=/tmp/.mount_pcsx2.i5w9Tp/usr/lib32/Langs
Cheats=${storagePath:?}/cheats
CheatsWS=/home/default/.config/PCSX2/cheats_ws
PluginsFolder=/tmp/.mount_pcsx2.i5w9Tp/usr/lib32/pcsx2
RunIso=${romsPath:?}/ps2
RunELF=/home/default/.config/PCSX2
EOF
fi

# Configure EmulationStation DE
mkdir -p "${romsPath:?}/ps2"
cat << 'EOF' > "${romsPath:?}/ps2/systeminfo.txt"
System name:
ps2

Full system name:
Sony Playstation 2

Supported file extensions:
.bin .BIN .chd .CHD .ciso .CISO .cso .CSO .dump .DUMP .elf .ELF .gz .GZ .m3u .M3U .mdf .MDF .img .IMG .iso .ISO .isz .ISZ .nrg .NRG

Launch command:
%EMULATOR_PCSX2% -batch %ROM%

Alternative launch commands:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/pcsx2_libretro.so %ROM%
%EMULATOR_PCSX2-LEGACY% --nogui %ROM%
%EMULATOR_PLAY!% --disc %ROM%

Platform (for scraping):
ps2

Theme folder:
ps2
EOF
if ! grep -ri "ps2:" "${romsPath:?}/systems.txt" &>/dev/null; then
    print_step_header "Adding 'ps2' path to '${romsPath:?}/systems.txt'"
    echo "ps2: " >> "${romsPath:?}/systems.txt"
    chown -R ${PUID:?}:${PGID:?} "${romsPath:?}/systems.txt"
fi
sed -i 's|^ps2:.*$|ps2: Sony Playstation 2|' "${romsPath:?}/systems.txt"
ensure_esde_alternative_emulator_configured "ps2" "PCSX2 (Standalone)"

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.config/PCSX2 \
    "${savesPath:?}"/pcsx2/memcards \
    "${savesPath:?}"/pcsx2/sstates \
    "${biosPath:?}"/pcsx2 \
    "${storagePath:?}"/pcsx2/snaps \
    "${storagePath:?}"/pcsx2/cheats \
    "${romsPath:?}"/ps2

echo "DONE"
