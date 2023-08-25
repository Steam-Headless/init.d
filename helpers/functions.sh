#!/usr/bin/env bash
###
# File: functions.sh
# Project: helpers
# File Created: Friday, 25th August 2023 4:26:49 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 25th August 2023 7:14:07 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

function print_package_name {
    echo "**** ${package_name:?} ****"
}

function print_step_header {
    echo "  - ${@:?}"
}

function fetch_appimage_and_make_executable {
    wget -O "${package_executable:?}" \
        --quiet -o /dev/null \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        "${@:?}"
    chmod +x "${package_executable:?}"
    chown -R ${PUID:?}:${PGID:?} "${package_executable:?}"
}

function ensure_menu_shortcut {
    mkdir -p "${USER_HOME:?}/.local/share/applications"

    # Download an icon image
    __local_package_icon_path="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"
    if [[ ! -f "${__local_package_icon_path:?}" && "X${package_icon_url:-}" != "X" ]]; then
        wget -O "${__local_package_icon_path:?}" \
            --quiet -o /dev/null \
            --no-verbose --show-progress \
            --progress=bar:force:noscroll \
            "${package_icon_url:?}"
        chown -R ${PUID:?}:${PGID:?} "${package_icon_url:?}"
    fi

    # Generate the desktop shortcut
    if ! grep -ri "${package_executable:?}" "${USER_HOME:?}/.local/share/applications/" &>/dev/null; then
        menu_shortcut="${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
        cat <<EOF >"${menu_shortcut:?}"
#!/usr/bin/env xdg-open
[Desktop Entry]
Name=${package_name:?}
Exec="${package_executable:?}" %U
Comment="${package_description:?}"
Icon="${__local_package_icon_path:?}"
Type=Application
Categories=${package_category:?};
TryExec=${package_executable:?}
Terminal=false
StartupNotify=false
EOF
        chown -R ${PUID:?}:${PGID:?} "${menu_shortcut:?}"
        chmod 644 "${menu_shortcut:?}"
    fi
}
