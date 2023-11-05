#!/usr/bin/env bash
###
# File: install-retroarch.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 17th September 2023 4:26:26 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install Retroarch during container startup.
#   This will also configure Retroarch with some default options for Steam Headless.
#   It will also configure the Retroarch AppImage as the default emulator for default systems in ES-DE.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/install-retroarch.sh" "${USER_HOME:?}/init.d/install-retroarch.sh"
#
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"
source "${USER_HOME:?}/init.d/helpers/functions-es-de-config.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


# Config
package_name="RetroArch-Linux"
package_description="Multi System Emulator"
package_icon_url="https://cdn2.steamgriddb.com/file/sgdb-cdn/icon/b36fd154dd0df788b77b7cfe39200ba3.png"
package_executable="${USER_HOME:?}/.local/bin/${package_name:?}.AppImage"
package_category="Game"
print_package_name


# Check for a new version to install
__latest_package_version=$(curl --silent -L "https://buildbot.libretro.com/stable" | grep -oE 'href="[^"]*/stable/[^"]*' | cut -d '/' -f 3 | sort --version-sort | tail -n 2 | head -n 1)
__latest_package_url="https://buildbot.libretro.com/stable/${__latest_package_version:?}/linux/x86_64/RetroArch.7z"
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"
__installed_version=$(catalog -g ${package_name,,})


# Only install if the latest version does not already exist locally
if ([ ! -f "${package_executable:?}" ] || [ "${__installed_version:-X}" != "${__latest_package_version:?}" ]); then
    __download_dir="${USER_HOME:?}/Downloads"
    # Download and extract package to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    mkdir -p "${__download_dir:?}" \
             "${USER_HOME:?}/.config/retroarch"
    wget -O "${__download_dir:?}/${package_name,,}-${__latest_package_version:?}-linux-x86_64.7z" \
        --quiet -o /dev/null \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        "${__latest_package_url:?}"

    # Install package
    print_step_header "Installing ${package_name:?} version ${__latest_package_version:?}"
    pushd "${__download_dir:?}" &> /dev/null || { echo "Error: Failed to push directory to ${__download_dir:?}"; exit 1; }
    
    # Move appimage to es-de default path
    7z x "${__download_dir:?}/${package_name,,}-${__latest_package_version:?}-linux-x86_64.7z" -aoa
    mv -f "${__download_dir:?}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage" "${package_executable:?}"
    rm "${__download_dir:?}/${package_name,,}-${__latest_package_version:?}-linux-x86_64.7z"
    
    # Always Download cores for a new release
    print_step_header "Downloading and Extracting cores..."
    wget -O "${__download_dir:?}/RetroArch_cores.7z" \
        --quiet -o /dev/null \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        "https://buildbot.libretro.com/stable/${__latest_package_version:?}/linux/x86_64/RetroArch_cores.7z"
    7z x "${__download_dir:?}/RetroArch_cores.7z" -aoa
    rsync -aP "${__download_dir:?}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch" "${USER_HOME:?}/.config/"
    rm "${__download_dir:?}/RetroArch_cores.7z"
    
    # Download Assets for a clean ui running retroarch natively
    print_step_header "Downloading and Extracting assets..."
	wget -O "${__download_dir:?}/assets.zip" \
		--quiet -o /dev/null \
		--no-verbose --show-progress \
		--progress=bar:force:noscroll \
		"https://buildbot.libretro.com/assets/frontend/assets.zip"
    unzip -d assets "${__download_dir:?}/assets.zip"
	rsync -aP "${__download_dir:?}/assets" "${USER_HOME:?}/.config/retroarch/"
    rm -r "${__download_dir:?}/assets" "assets.zip"

    # Download Autoconfig for automatic controller support
    print_step_header "Downloading and Extracting controller autoconfig..."
	wget -O "${__download_dir:?}/autoconfig.zip" \
		--quiet -o /dev/null \
		--no-verbose --show-progress \
		--progress=bar:force:noscroll \
		"https://buildbot.libretro.com/assets/frontend/autoconfig.zip"

	unzip -d autoconfig "${__download_dir:?}/autoconfig.zip"
	rsync -aP "${__download_dir:?}/autoconfig" "${USER_HOME:?}/.config/retroarch/"
    rm -r "${__download_dir:?}/autoconfig" "autoconfig.zip"

    # Cleanup Download Dir
    rm -r "${__download_dir:?}/RetroArch-Linux-x86_64"

    popd &> /dev/null || { echo "Error: Failed to pop directory out of ${__download_dir:?}"; exit 1; }

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu shortcut is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    catalog -s ${package_name,,} ${__latest_package_version:?}
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi

# Generate RetroArch Emulation directory structure
__emulation_path="/mnt/games/Emulation"
__retroarch_home="${USER_HOME:?}/.config/retroarch"
mkdir -p \
    "${__retroarch_home:?}" \
    "${__emulation_path:?}"/storage/retroarch/{cheats,shaders,config,saves,screenshots,states,system}

ensure_symlink "${__emulation_path:?}/storage/retroarch/cheats" "${__retroarch_home:?}/cheats"
ensure_symlink "${__emulation_path:?}/storage/retroarch/config" "${__retroarch_home:?}/config"
ensure_symlink "${__emulation_path:?}/storage/retroarch/saves" "${__retroarch_home:?}/saves"
ensure_symlink "${__emulation_path:?}/storage/retroarch/screenshots" "${__retroarch_home:?}/screenshots"
ensure_symlink "${__emulation_path:?}/storage/retroarch/states" "${__retroarch_home:?}/states"
ensure_symlink "${__emulation_path:?}/storage/retroarch/system" "${__retroarch_home:?}/system"
ensure_symlink "${__emulation_path:?}/storage/retroarch/shaders" "${__retroarch_home:?}/shaders"

# Create relative symlinks for the BIOS 
ensure_symlink "../storage/retroarch/system" "${__emulation_path:?}/bios/retroarch"

# Generate a default config if missing
if [ ! -f "${__retroarch_home:?}/retroarch.cfg" ]; then
    cat << EOF > "${__retroarch_home:?}/retroarch.cfg"
cheat_database_path = "${__emulation_path:?}/storage/retroarch/cheats"
config_save_on_exit = "true"
input_menu_toggle_gamepad_combo = "2"
input_quit_gamepad_combo = "9"
menu_swap_ok_cancel_buttons = "true"
pause_on_disconnect = "true"
quit_press_twice = "false"
quit_on_close_content = "1"
rgui_config_directory = "${__emulation_path:?}/storage/retroarch/config"
savefile_directory = "${__emulation_path:?}/storage/retroarch/saves"
savestate_directory = "${__emulation_path:?}/storage/retroarch/states"
screenshot_directory = "${__emulation_path:?}/storage/retroarch/screenshots"
video_shader_dir = "${__emulation_path:?}/storage/retroarch/shaders"
input_remapping_directory = "${__emulation_path:?}/storage/retroarch/config/remaps"
sort_savefiles_by_content_enable = "false"
sort_savefiles_enable = "true"
sort_savestates_by_content_enable = "false"
sort_savestates_enable = "true"
sort_screenshots_by_content_enable = "false"
savestate_auto_load = "true"
savestate_auto_save = "true"
system_directory = "${__emulation_path:?}/storage/retroarch/system"
video_driver = "vulkan"
video_fullscreen = "true"
EOF
fi

echo "DONE"