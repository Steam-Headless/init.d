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
__latest_registery_url=$(wget -O - -o /dev/null https://api.github.com/repos/PCSX2/pcsx2/releases | jq -r '.[0].url')
__registry_package_json=$(wget -O - -o /dev/null $(echo ${__latest_registery_url}))
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
    "${USER_HOME:?}"/.config/PCSX2/inis \
    "${__emulation_path:?}"/storage/pcsx2/{memcards,sstates,snaps,cheats,cache,covers,bios,patches,textures} \
    "${__emulation_path:?}"/roms/ps2

ensure_symlink "${__emulation_path:?}/storage/pcsx2/memcards" "${USER_HOME:?}/.config/PCSX2/memcards"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/sstates" "${USER_HOME:?}/.config/PCSX2/sstates"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/snaps" "${USER_HOME:?}/.config/PCSX2/snaps"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/cheats" "${USER_HOME:?}/.config/PCSX2/cheats"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/cache" "${USER_HOME:?}/.config/PCSX2/cache"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/covers" "${USER_HOME:?}/.config/PCSX2/covers"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/bios" "${USER_HOME:?}/.config/PCSX2/bios"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/patches" "${USER_HOME:?}/.config/PCSX2/patches"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/textures" "${USER_HOME:?}/.config/PCSX2/textures"

# Generate a default config if missing
# Currently need to run PCSX2 once to import the config, can't figure out how to bypass it
if [ ! -f "${USER_HOME:?}/.config/PCSX2/inis/PCSX2.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.config/PCSX2/inis/PCSX2.ini"
[UI]
SettingsVersion = 1
InhibitScreensaver = true
ConfirmShutdown = false
StartPaused = false
PauseOnFocusLoss = false
StartFullscreen = true
DoubleClickTogglesFullscreen = true
HideMouseCursor = true
RenderToSeparateWindow = false
HideMainWindowWhenRunning = false
DisableWindowResize = false
Theme = darkfusion
SetupWizardIncomplete = false


[Folders]
Bios = ${__emulation_path:?}/storage/pcsx2/bios
Snapshots = ${__emulation_path:?}/storage/pcsx2/snaps
SaveStates = ${__emulation_path:?}/storage/pcsx2/sstates
MemoryCards = ${__emulation_path:?}/storage/pcsx2/memcards
Logs = logs
Cheats = ${__emulation_path:?}/storage/pcsx2/cheats
Patches = ${__emulation_path:?}/storage/pcsx2/patches
Cache = ${__emulation_path:?}/storage/pcsx2/cache
Textures = ${__emulation_path:?}/storage/pcsx2/textures
InputProfiles = inputprofiles
Videos = videos
Covers = ${__emulation_path:?}/storage/pcsx2/covers


[Hotkeys]
ToggleFullscreen = Keyboard/Alt & Keyboard/Return
CycleAspectRatio = Keyboard/F6
CycleInterlaceMode = Keyboard/F5
CycleMipmapMode = Keyboard/Insert
GSDumpMultiFrame = Keyboard/Control & Keyboard/Shift & Keyboard/F8
Screenshot = Keyboard/F8
GSDumpSingleFrame = Keyboard/Shift & Keyboard/F8
ToggleSoftwareRendering = Keyboard/F9
ZoomIn = Keyboard/Control & Keyboard/Plus
ZoomOut = Keyboard/Control & Keyboard/Minus
InputRecToggleMode = Keyboard/Shift & Keyboard/R
LoadStateFromSlot = Keyboard/F3
SaveStateToSlot = Keyboard/F1
NextSaveStateSlot = Keyboard/F2
PreviousSaveStateSlot = Keyboard/Shift & Keyboard/F2
OpenPauseMenu = Keyboard/Escape
ToggleFrameLimit = Keyboard/F4
TogglePause = Keyboard/Space
ToggleSlowMotion = Keyboard/Shift & Keyboard/Backtab
ToggleTurbo = Keyboard/Tab
HoldTurbo = Keyboard/Period


[AutoUpdater]
CheckAtStartup = false


[GameList]
RecursivePaths = ${__emulation_path:?}/roms/ps2
EOF
fi

# Configure EmulationStation DE
cat << 'EOF' > "${__emulation_path:?}/roms/ps2/systeminfo.txt"
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
if ! grep -ri "ps2:" "${__emulation_path:?}/roms/systems.txt" &>/dev/null; then
    print_step_header "Adding 'ps2' path to '${__emulation_path:?}/roms/systems.txt'"
    echo "ps2: " >> "${__emulation_path:?}/roms/systems.txt"
    chown -R ${PUID:?}:${PGID:?} "${__emulation_path:?}/roms/systems.txt"
fi
sed -i 's|^ps2:.*$|ps2: Sony Playstation 2|' "${__emulation_path:?}/roms/systems.txt"
ensure_esde_alternative_emulator_configured "ps2" "PCSX2 (Standalone)"

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.config/PCSX2 \
    "${__emulation_path:?}"/roms/ps2 \
    "${__emulation_path:?}"/storage/pcsx2

echo "DONE"
