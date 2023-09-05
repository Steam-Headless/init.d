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
package_icon_url="https://git.libretro.com/libretro-assets/retroarch-assets/-/blob/52ab08994b83dda5d3350661c8874bbf3fb1211d/ozone/png/icons/retroarch.png"
package_executable="${USER_HOME:?}/.local/bin/${package_name:?}.AppImage"
package_category="Game"
package_icon="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"


source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
source "${USER_HOME:?}/init.d/helpers/functions.sh"
source "${USER_HOME:?}/init.d/helpers/functions-es-de-config.sh"
print_package_name

# Check for a new version to install
__latest_registery_url_qt="https://buildbot.libretro.com/nightly/linux/x86_64/RetroArch_Qt.7z"
__latest_registery_url="https://buildbot.libretro.com/nightly/linux/x86_64/RetroArch.7z"


# Only install if the latest version does not already exist locally
if [ ! -f "${package_executable:?}" ] || [ ! -f "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}" ]; then
	__install_dir="${USER_HOME:?}/.local/share/${package_name,,}"
	# Download Appimage to Applications directory
    print_step_header "Downloading ${package_name:?}"
	mkdir -p "${__install_dir:?}"
	wget -O "${__install_dir:?}/${package_name,,}_x64.7z" \
		--quiet -o /dev/null \
		--no-verbose --show-progress \
		--progress=bar:force:noscroll \
		"${__latest_registery_url_qt:?}"
	# Install package
	print_step_header "Installing ${package_name:?}"
	pushd "${__install_dir:?}" &> /dev/null || { echo "Error: Failed to push directory to ${__install_dir:?}"; exit 1; }
	p7zip -d "${__install_dir:?}/${package_name,,}_x64.7z"
	mkdir -p "${USER_HOME:?}/.local/bin"
	ln -snf "${__install_dir:?}/RetroArch-Linux-x86_64.AppImage" "${USER_HOME:?}/.local/bin/RetroArch-Linux.AppImage"
	chmod +x "${__install_dir:?}/RetroArch-Linux.AppImage"
	chown ${PUID:?}:${PGID:?} "${USER_HOME:?}"/.local/bin/RetroArch-Linux.AppImage
	chown -R ${PUID:?}:${PGID:?} "${__install_dir:?}"
	popd &> /dev/null || { echo "Error: Failed to pop directory out of ${__install_dir:?}"; exit 1; }

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu short is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    touch "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}"
else
    print_step_header "${package_name:?} already installed"
fi

# Generate RetroArch Emulation directory structure
__emulation_path="/mnt/games/Emulation"
__retroarch_home="${USER_HOME:?}"/.local/share/RetroArch-Linux/RetroArch-Linux-x86_64.AppImage.home
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
#if [ ! -f "${__retroarch_home:?}/.config/retroarch/retroarch.cfg" ]; then
#    cat << EOF > "${__retroarch_home:?}/.config/retroarch/retroarch.cfg"
#
#EOF
#fi

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.local/share/RetroArch-Linux \
    "${__emulation_path:?}"/storage/retroarch

echo "DONE"
