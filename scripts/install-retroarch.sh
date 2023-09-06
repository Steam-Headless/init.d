#!/usr/bin/env bash
###
# File: install-retroarch.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 1st September 2023 1:34:02 pm
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


# Config
package_name="RetroArch-Linux"
package_description="Multi System Emulator"
package_icon_url="https://cdn2.steamgriddb.com/file/sgdb-cdn/icon/b36fd154dd0df788b77b7cfe39200ba3.png"
package_executable="${USER_HOME:?}/.local/bin/${package_name:?}.AppImage"
package_category="Game"


source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
source "${USER_HOME:?}/init.d/helpers/functions.sh"
source "${USER_HOME:?}/init.d/helpers/functions-es-de-config.sh"
print_package_name

set +e

# Check for a new version to install
__buildbot_html_content=$(curl --silent "https://buildbot.libretro.com/nightly/linux/x86_64/")
__latest_package_href=$(echo "${__buildbot_html_content:?}" | grep -oE 'href="[^"]*_RetroArch\.7z"[^"]*"' | sort -t '/' -k 5,5 -k 4,4 -k 3,3 | tail -n 1 | cut -d '"' -f 2)
__latest_package_version=$(echo "${__latest_package_href:?}" | awk -F'/' '{print $5}' | cut -d'_' -f1)
__latest_package_url="https://buildbot.libretro.com${__latest_package_href:?}"
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"


# Only install if the latest version does not already exist locally
if [ ! -f "${package_executable:?}" ] || [ ! -f "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}" ]; then
    __install_dir="${USER_HOME:?}/.local/share/retroarch"
    # Download and extract package to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    mkdir -p "${__install_dir:?}"
    wget -O "${__install_dir:?}/${package_name,,}-${__latest_package_version:?}-linux-x86_64.7z" \
        --quiet -o /dev/null \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        "${__latest_package_url:?}"

    # Install package
    print_step_header "Installing ${package_name:?} version ${__latest_package_version:?}"
    pushd "${__install_dir:?}" &> /dev/null || { echo "Error: Failed to push directory to ${__install_dir:?}"; exit 1; }
    7z x "${__install_dir:?}/${package_name,,}-${__latest_package_version:?}-linux-x86_64.7z"
    mkdir -p "${USER_HOME:?}/.local/bin"
    ln -snf "${__install_dir:?}/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage" "${package_executable:?}"
    chown ${PUID:?}:${PGID:?} "${package_executable:?}"
    chown -R ${PUID:?}:${PGID:?} "${__install_dir:?}"
    popd &> /dev/null || { echo "Error: Failed to pop directory out of ${__install_dir:?}"; exit 1; }
	
	# Download cores if they do not exist, if they exist user can update them using the UI
	if [ ! -f "${__install_dir:?}/RetroArch_cores.7z" ]; then
		print_step_header "Downloading and Extracting cores..."
		wget -O "${__install_dir:?}/RetroArch_cores.7z" \
			--quiet -o /dev/null \
			--no-verbose --show-progress \
			--progress=bar:force:noscroll \
			"https://buildbot.libretro.com/nightly/linux/x86_64/RetroArch_cores.7z"
		pushd "${__install_dir:?}" &> /dev/null || { echo "Error: Failed to push directory to ${__install_dir:?}"; exit 1; }
		7z x "${__install_dir:?}/RetroArch_cores.7z" -aoa
		mkdir -p "${USER_HOME:?}/.config/retroarch"
		ln -snf "${USER_HOME:?}/.local/share/retroarch/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home/.config/retroarch/cores" "${USER_HOME:?}/.config/retroarch/"
		popd &> /dev/null || { echo "Error: Failed to pop directory out of ${__install_dir:?}"; exit 1; }
	fi

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu shortcut is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    touch "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}"
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi

# Generate RetroArch Emulation directory structure
__emulation_path="/mnt/games/Emulation"
__retroarch_home="${USER_HOME:?}/.local/share/retroarch/RetroArch-Linux-x86_64/RetroArch-Linux-x86_64.AppImage.home"
mkdir -p \
    "${__retroarch_home:?}"/.config/retroarch \
    "${__emulation_path:?}"/storage/retroarch/{cheats,config,saves,screenshots,states,system}

ensure_symlink "${__emulation_path:?}/storage/retroarch/cheats" "${__retroarch_home:?}/.config/retroarch/cheats"
ensure_symlink "${__emulation_path:?}/storage/retroarch/config" "${__retroarch_home:?}/.config/retroarch/config"
ensure_symlink "${__emulation_path:?}/storage/retroarch/saves" "${__retroarch_home:?}/.config/retroarch/saves"
ensure_symlink "${__emulation_path:?}/storage/retroarch/screenshots" "${__retroarch_home:?}/.config/retroarch/screenshots"
ensure_symlink "${__emulation_path:?}/storage/retroarch/states" "${__retroarch_home:?}/.config/retroarch/states"
ensure_symlink "${__emulation_path:?}/storage/retroarch/system" "${__retroarch_home:?}/.config/retroarch/system"

# Generate a default config if missing
if [ ! -f "${__retroarch_home:?}/.config/retroarch/retroarch.cfg" ]; then
    cat << EOF > "${__retroarch_home:?}/.config/retroarch/retroarch.cfg"
assets_directory = "${__emulation_path:?}/storage/retroarch/assets"
cheat_database_path = "${__emulation_path:?}/storage/retroarch/cheats"
config_save_on_exit = "true"
input_menu_toggle_gamepad_combo = "2"
input_quit_gamepad_combo = "9"
pause_on_disconnect = "true"
quit_press_twice = "false"
quit_on_close_content = "1"
savefile_directory = "${__emulation_path:?}/storage/retroarch/saves"
savestate_directory = "${__emulation_path:?}/storage/retroarch/states"
screenshot_directory = "${__emulation_path:?}/storage/retroarch/screenshots"
sort_savefiles_by_content_enable = "false"
sort_savefiles_enable = "true"
sort_savestates_by_content_enable = "false"
sort_savestates_enable = "true"
sort_screenshots_by_content_enable = "false"
system_directory = "${__emulation_path:?}/storage/retroarch/system"
video_driver = "vulkan"
video_fullscreen = "true"
EOF
fi

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.local/share/retroarch \
    "${__emulation_path:?}"/storage/retroarch

echo "DONE"