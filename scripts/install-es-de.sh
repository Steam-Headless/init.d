#!/usr/bin/env bash
###
# File: install-es-de.sh
# Project: scripts
# File Created: Wednesday, 23rd August 2023 7:16:02 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Wednesday, 23rd August 2023 7:51:39 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

set -e

# Config
package_name="EmulationStation-DE"
package_description="EmulationStation Desktop Edition (ES-DE) is a frontend for browsing and launching games from your multi-platform game collection."
package_icon_url="https://es-de.org/____impro/1/onewebmedia/ES-DE_logo.png?etag=%22621b-60428790%22&sourceContentType=image%2Fpng"
package_path="${USER_HOME:?}/.local/share/${package_name:?}"


# Run
__registry_package_json=$(curl -s https://gitlab.com/api/v4/projects/es-de%2Femulationstation-de/packages)
__latest_package_version=$(echo ${__registry_package_json} | jq -c 'map(select(.name | contains("ES-DE_Stable")))' | jq -r '.[-1].version')
__latest_package_id=$(echo ${__registry_package_json} | jq -c 'map(select(.name | contains("ES-DE_Stable")))' | jq -r '.[-1].id')
echo "Latest ${package_name:?} version: ${__latest_package_version:?}"

mkdir -p "${package_path:?}"
__local_package_path="${package_path:?}/${package_name}-${__latest_package_version:?}.AppImage"
__local_package_icon_path="${package_path:?}/icon.png"

# Only install if it does not already exist
if [[ ! -f "${__local_package_path:?}" ]]; then
    echo "**** Installing ${package_name} version ${__latest_package_version:?} ****"

    # Fetch download links
    __latest_package_files_json=$(curl -s https://gitlab.com/api/v4/projects/es-de%2Femulationstation-de/packages/${__latest_package_id:?}/package_files)
    __latest_package_file_id=$(echo ${__latest_package_files_json} | jq -c 'map(select(.file_name | contains("x64.AppImage")))' | jq -r '.[-1].id')
    __latest_package_file_sha256=$(echo ${__latest_package_files_json} | jq -c 'map(select(.file_name | contains("x64.AppImage")))' | jq -r '.[-1].file_sha256')

    # Download Appimage
    wget -O "${__local_package_path:?}" \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        "https://gitlab.com/es-de/emulationstation-de/-/package_files/${__latest_package_file_id:?}/download"
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
