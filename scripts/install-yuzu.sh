#!/usr/bin/env bash
###
# File: install-yuzu.sh
# Project: scripts
# File Created: Wednesday, 23rd August 2023 7:16:02 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Wednesday, 23rd August 2023 7:51:39 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

set -e

# Config
package_name="Yuzu"
package_description="Nintendo Switch Emulator"
package_icon_url="https://raw.githubusercontent.com/yuzu-emu/yuzu-assets/master/icons/icon.png"
package_path="${USER_HOME:?}/.local/share/${package_name:?}"


# Run
__registry_package_json=$(curl -s https://api.github.com/repos/yuzu-emu/yuzu-mainline/releases/latest)
__latest_package_version=$(echo ${__registry_package_json} | jq -r ".assets[2] | .name" | cut -d "-" -f 4 | cut -d "." -f 1)
__latest_package_id=$(echo ${__registry_package_json} | jq -r ".assets[2] | .name" | cut -d "-" -f 2,3)
echo "Latest ${package_name:?} version: ${__latest_package_version:?}"

mkdir -p "${package_path:?}"
__local_package_path="${package_path:?}/${package_name}-${__latest_package_version:?}.AppImage"
__local_package_icon_path="${package_path:?}/icon.png"

# Only install if it does not already exist
if [[ ! -f "${__local_package_path:?}" ]]; then
    echo "**** Installing ${package_name} version ${__latest_package_version:?} ****"

    # Fetch download links
    __latest_url=$(curl -s https://api.github.com/repos/yuzu-emu/yuzu-mainline/releases/latest | jq -r ".assets[2] | .browser_download_url")

    # Download Appimage
    wget -O "${__local_package_path:?}" \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        ${__latest_url}
    chmod +x "${__local_package_path:?}"

    # Download an icon image
    if [[ ! -f "${__local_package_icon_path:?}" && "X${package_icon_url:-}" != "X" ]]; then
        wget -O "${__local_package_icon_path:?}" \
            --no-verbose --show-progress \
            --progress=bar:force:noscroll \
            "${package_icon_url:?}"
    fi

    # Write a start menu link
    if ! grep -ri "${__local_package_path:?}" "${USER_HOME:?}/.local/share/applications/"; then
        mkdir -p "${USER_HOME:?}/.local/share/applications"
        menu_shortcut="${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
        echo '#!/usr/bin/env xdg-open' > "${menu_shortcut:?}"
        echo '[Desktop Entry]' >> "${menu_shortcut:?}"
        echo 'Name='${package_name:?} >> "${menu_shortcut:?}"
        echo 'Exec="'${__local_package_path:?}'" %U' >> "${menu_shortcut:?}"
        echo 'Comment="'${package_description:?}'"' >> "${menu_shortcut:?}"
        echo 'Icon='${__local_package_icon_path:?} >> "${menu_shortcut:?}"
        echo 'Type=Application' >> "${menu_shortcut:?}"
        echo 'Categories=Game;' >> "${menu_shortcut:?}"
        echo 'TryExec='${__local_package_path:?} >> "${menu_shortcut:?}"
        echo 'Terminal=false' >> "${menu_shortcut:?}"
        echo 'StartupNotify=false' >> "${menu_shortcut:?}"
        chown -R ${PUID:?}:${PGID:?} "${menu_shortcut:?}"
        chmod 644 "${menu_shortcut:?}"
    fi

    chown -R ${PUID:?}:${PGID:?} "${package_path:?}"
else
    echo "**** Latest version of ${package_name} version ${__latest_package_version:?} already installed ****"
fi
