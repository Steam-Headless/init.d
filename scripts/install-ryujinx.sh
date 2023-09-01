#!/usr/bin/env bash
###
# File: install-ryujinx.sh
# Project: scripts
# File Created: Friday, 1st September 2023 3:57:42 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 1st September 2023 4:59:43 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###


# Config
package_name="Ryujinx"
package_description="Nintendo Switch Emulator"
package_icon_url="https://i.imgur.com/WcCj6Rt.png"
package_executable="${USER_HOME:?}/.local/bin/${package_name,,}"
package_category="Game"
package_icon="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"


source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
source "${USER_HOME:?}/init.d/helpers/functions.sh"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/Ryujinx/release-channel-master/releases/latest)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.tag_name')
__latest_package_id=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith("-linux_x64.tar.gz") and startswith("ryujinx-")) | .id' | head -n 1)
__latest_package_url=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith("-linux_x64.tar.gz") and startswith("ryujinx-")) | .browser_download_url' | head -n 1)
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"


# Only install if the latest version does not already exist locally
if [ ! -f "${package_executable:?}" ] || [ ! -f "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}" ]; then
    __install_dir="${USER_HOME:?}/.local/share/${package_name,,}"
    # Download and extract package to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    mkdir -p "${__install_dir:?}"
    wget -O "${__install_dir:?}/${package_name,,}-${__latest_package_version:?}-linux_x64.tar.gz" \
        --quiet -o /dev/null \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        "${__latest_package_url:?}"

    # Install package
    print_step_header "Installing ${package_name:?} version ${__latest_package_version:?}"
    pushd "${__install_dir:?}" &> /dev/null || { echo "Error: Failed to push directory to ${__install_dir:?}"; exit 1; }
    tar -xf "${__install_dir:?}/${package_name,,}-${__latest_package_version:?}-linux_x64.tar.gz"
    mkdir -p "${USER_HOME:?}/.local/bin"
    ln -snf "${__install_dir:?}/publish/Ryujinx.sh" "${package_executable:?}"
    chown ${PUID:?}:${PGID:?} "${package_executable:?}"
    chown -R ${PUID:?}:${PGID:?} "${__install_dir:?}"
    popd &> /dev/null || { echo "Error: Failed to pop directory out of ${__install_dir:?}"; exit 1; }

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu short is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    touch "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}"
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi

echo "DONE"
