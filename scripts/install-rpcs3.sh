#!/usr/bin/env bash
###
# File: install-rpcs3.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 17th September 2023 4:26:27 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"
source "${USER_HOME:?}/init.d/helpers/functions-es-de-config.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


# Config
package_name="rpcs3"
package_description="Sony Playstation 3 Emulator"
package_icon_url="https://cdn2.steamgriddb.com/file/sgdb-cdn/icon/add5aebfcb33a2206b6497d53bc4f309/32/24x24.png"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/RPCS3/rpcs3-binaries-linux/releases/latest)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.tag_name')
__latest_package_id=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.id')
__latest_package_url=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.browser_download_url')
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"


# Only install if the latest version does not already exist locally
if ([ ! -f "${package_executable:?}" ] || [ ! -f "/tmp/.user-script-${package_name,,}-installed" ]); then
    # Download Appimage to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    fetch_appimage_and_make_executable "${__latest_package_url:?}"

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu short is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    touch "/tmp/.user-script-${package_name,,}-installed"
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi

# Generate rpcs3 Emulation directory structure
__emulation_path="/mnt/games/Emulation"
mkdir -p \
    "${USER_HOME:?}"/.config/rpcs3/dev_hdd0/home \
    "${USER_HOME:?}"/.config/rpcs3/input_configs/global \
    "${__emulation_path:?}"/storage/rpcs3/{home,savestates,patches} \
    "${__emulation_path:?}"/roms/ps3

ensure_symlink "${__emulation_path:?}/storage/rpcs3/home" "${USER_HOME:?}/.config/rpcs3/dev_hdd0/home"
ensure_symlink "${__emulation_path:?}/storage/rpcs3/savestates" "${USER_HOME:?}/.config/rpcs3/savestates"
ensure_symlink "${__emulation_path:?}/storage/rpcs3/patches" "${USER_HOME:?}/.config/rpcs3/patches"


# Generate a default config if missing
if [ ! -f "${USER_HOME:?}/.config/rpcs3/config.yml" ]; then
    cat << EOF > "${USER_HOME:?}/.config/rpcs3/config.yml"
Video:
  Stretch To Display Area: true
  Multithreaded RSX: true
  Resolution Scale: 150
Miscellaneous:
  Exit RPCS3 when process finishes: true
  Pause emulation on RPCS3 focus loss: true
  Start games in fullscreen mode: true
  Prevent display sleep while running games: true
EOF
fi

# Generate a default config if missing
if [ ! -f "${USER_HOME:?}/.config/rpcs3/input_configs/global/Default.yml" ]; then
    cat << EOF > "${USER_HOME:?}/.config/rpcs3/input_configs/global/Default.yml"
Player 1 Input:
  Handler: SDL
  Device: X360 Controller 1
  Config:
    Left Stick Left: LS X-
    Left Stick Down: LS Y-
    Left Stick Right: LS X+
    Left Stick Up: LS Y+
    Right Stick Left: RS X-
    Right Stick Down: RS Y-
    Right Stick Right: RS X+
    Right Stick Up: RS Y+
    Start: Start
    Select: Back
    PS Button: Guide
    Square: X
    Cross: A
    Circle: B
    Triangle: Y
    Left: Left
    Down: Down
    Right: Right
    Up: Up
    R1: RB
    R2: RT
    R3: RS
    L1: LB
    L2: LT
    L3: LS
    Motion Sensor X:
      Axis: ""
      Mirrored: false
      Shift: 0
    Motion Sensor Y:
      Axis: ""
      Mirrored: false
      Shift: 0
    Motion Sensor Z:
      Axis: ""
      Mirrored: false
      Shift: 0
    Motion Sensor G:
      Axis: ""
      Mirrored: false
      Shift: 0
    Pressure Intensity Button: ""
    Pressure Intensity Percent: 50
    Pressure Intensity Toggle Mode: false
    Pressure Intensity Deadzone: 0
    Left Stick Multiplier: 100
    Right Stick Multiplier: 100
    Left Stick Deadzone: 8000
    Right Stick Deadzone: 8000
    Left Trigger Threshold: 0
    Right Trigger Threshold: 0
    Left Pad Squircling Factor: 8000
    Right Pad Squircling Factor: 8000
    Color Value R: 0
    Color Value G: 0
    Color Value B: 20
    Blink LED when battery is below 20%: true
    Use LED as a battery indicator: false
    LED battery indicator brightness: 10
    Player LED enabled: true
    Enable Large Vibration Motor: true
    Enable Small Vibration Motor: true
    Switch Vibration Motors: false
    Mouse Movement Mode: Relative
    Mouse Deadzone X Axis: 60
    Mouse Deadzone Y Axis: 60
    Mouse Acceleration X Axis: 200
    Mouse Acceleration Y Axis: 250
    Left Stick Lerp Factor: 100
    Right Stick Lerp Factor: 100
    Analog Button Lerp Factor: 100
    Trigger Lerp Factor: 100
    Device Class Type: 0
    Vendor ID: 1356
    Product ID: 616
  Buddy Device: ""
EOF
fi

# Note to user
touch "${__emulation_path:?}/roms/ps3/rename_rom_root_dirs_from_DIR_to_DIR.ps3dir.txt"

ensure_esde_alternative_emulator_configured "ps3" "RPCS3 Directory (Standalone)"

echo "DONE"
