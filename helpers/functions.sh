#!/usr/bin/env bash
###
# File: functions.sh
# Project: helpers
# File Created: Friday, 25th August 2023 4:26:49 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Wednesday, 6th September 2023 1:16:09 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###

function print_package_name {
    echo "**** ${package_name:?} ****"
}

function print_step_header {
    echo "  - ${@:?}"
}

function print_step_error {
    echo -e "    \e[31mERROR: \e[33m${@:?}\e[0m"
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

function install_xdg_icon {
    mkdir -p "${USER_HOME:?}"/.local/share/icons/hicolor/{256x256,48x48,32x32,24x24,16x16}/apps
    # Input icon name
    local __input_icon_name="${1}"
    # Input icon path
    local __input_icon_path="${@:2}"
    # Array of icon sizes
    local __sizes=("256x256" "48x48" "32x32" "24x24" "16x16")
    # Check if convert (ImageMagick) is available
    if command -v convert &>/dev/null; then
        # Temporary directory to store the scaled icons
        local __convert_temp_dir="$(mktemp -d)"
        # Loop over sizes and create scaled icons
        for size in "${__sizes[@]}"; do
            mkdir -p "${__convert_temp_dir:?}/${size:?}"
            chown -R ${PUID:?}:${PGID:?} "${__convert_temp_dir:?}"
            # Scale the icon to the desired size using ImageMagick's convert command
            convert "${__input_icon_path:?}" -resize "${size:?}" "${__convert_temp_dir:?}/${size:?}/${__input_icon_name:?}.png"
            # Install the scaled icon using xdg-icon-resource
            su - default -c "xdg-icon-resource install --novendor --mode user --size ${size%%x*} ${__convert_temp_dir:?}/${size:?}/${__input_icon_name:?}.png"
        done
        # Remove temp dir
        rm -rf "${__temp_dir:?}"
    else
        # If convert is not available, install a 256x256 version of the icon
        su - default -c "xdg-icon-resource install --novendor --mode user --size 256 ${__input_icon_path:?}"
    fi
    chown -R ${PUID:?}:${PGID:?} "${USER_HOME:?}/.local/share/icons"
}

function ensure_icon_exists {
    # Input icon name
    local __input_icon_name="${1}"
    # Input icon path
    local __input_icon_url="${@:2}"
    # Path to XDG icon
    local __package_icon_path="${USER_HOME:?}/.local/share/icons/hicolor/256x256/apps/${__input_icon_name:?}.png"
    # Check if the icon already exists
    if [[ ! -f "${__package_icon_path:?}" && "X${__input_icon_url:-}" != "X" ]]; then
        # Temporary directory for download
        local __temp_dir="$(mktemp -d)"
        wget -O "${__temp_dir:?}/${__input_icon_name:?}.png" \
            --quiet -o /dev/null \
            --no-verbose --show-progress \
            --progress=bar:force:noscroll \
            "${__input_icon_url:?}"
        # Install the icon
        chown -R ${PUID:?}:${PGID:?} "${__temp_dir:?}"
        install_xdg_icon "${__input_icon_name:?}" "${__temp_dir:?}/${__input_icon_name:?}.png"
        # Remove temp dir
        rm -rf "${__temp_dir:?}"
    fi
}

function ensure_menu_shortcut {
    mkdir -p "${USER_HOME:?}/.local/share/applications"

    # Download an icon image
    ensure_icon_exists "${package_name,,}" "${package_icon_url:?}"

    # Generate the desktop shortcut
    if ! grep -ri "${package_executable:?}" "${USER_HOME:?}/.local/share/applications/" &>/dev/null; then
        menu_shortcut="${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
        cat <<EOF >"${menu_shortcut:?}"
#!/usr/bin/env xdg-open
[Desktop Entry]
Name=${package_name:?}
Exec="${package_executable:?}" %U
Comment="${package_description:?}"
Icon=${package_name,,}
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

function ensure_sunshine_command_entry {
    __exec_cmd="${@:?}"

    # Ensure a sunshine config exists
    if [ ! -f "${USER_HOME:?}/.config/sunshine/apps.json" ]; then
        return
    fi

    # Ensure config file can be parsed by jq
    if ! cat "${USER_HOME:?}/.config/sunshine/apps.json" | jq &> /dev/null; then
        print_step_error "Unable to parse JSON in file '${USER_HOME:?}/.config/sunshine/apps.json'"
        return
    fi

    # Read current sunshine config
    __json=$(cat "${USER_HOME:?}/.config/sunshine/apps.json")

    # Check if an entry with the new cmd value already exists
    __exists=$(echo "${__json:?}" \
        | jq --arg new_cmd "${__exec_cmd:?}" \
        '.apps | map(.cmd) | contains([$new_cmd])')
    if [ "${__exists:?}" = "true" ]; then
        return
    fi

    # Check if an entry with the name value already exists (remove it if it does)
    __exists=$(echo "${__json:?}" \
        | jq --arg new_name "${package_name:?}" \
        '.apps | map(.name) | contains([$new_name])')
    if [ "${__exists:?}" = "true" ]; then
        __json=$(echo "${__json:?}" | jq --arg name_to_remove "${package_name:?}" '.apps |= map(select(.name != $name_to_remove))')
    fi

    # Download an icon image
    ensure_icon_exists "${package_name,,}" "${package_icon_url:?}"

    # Generate updated JSON for Sunshine's app.json file
    __updated_json=$(echo "$__json" | jq \
        --arg package_name "${package_name:?}" \
        --arg new_cmd "${__exec_cmd:?}" \
        --arg package_icon_path "${package_icon_path:?}" \
        --arg working_dir "${USER_HOME:?}" \
        '.apps += [{
            "name": $package_name,
            "output": "",
            "cmd": $new_cmd,
            "exclude-global-prep-cmd": "false",
            "elevated": "false",
            "image-path": $package_icon_path,
            "working-dir": $working_dir
    }]')

    # Override Sunshine's app.json config file
    echo "${__updated_json:?}" > "${USER_HOME:?}/.config/sunshine/apps.json"
}

function ensure_sunshine_detached_command_entry {
    __exec_cmd="${@:?}"

    # Ensure a sunshine config exists
    if [ ! -f "${USER_HOME:?}/.config/sunshine/apps.json" ]; then
        return
    fi

    # Ensure config file can be parsed by jq
    if ! cat "${USER_HOME:?}/.config/sunshine/apps.json" | jq &> /dev/null; then
        print_step_error "Unable to parse JSON in file '${USER_HOME:?}/.config/sunshine/apps.json'"
        return
    fi

    # Read current sunshine config
    __json=$(cat "${USER_HOME:?}/.config/sunshine/apps.json")

    # Check if an entry with the new cmd value already exists
    __exists=$(echo "${__json:?}" \
        | jq --arg new_cmd "${__exec_cmd:?}" \
        '.apps[] | select(.detached[]? | contains($new_cmd)) | any')
    if [ "${__exists:-}" = "true" ]; then
        return
    fi

    # Check if an entry with the name value already exists (remove it if it does)
    __exists=$(echo "${__json:?}" \
        | jq --arg new_name "${package_name:?}" \
        '.apps | map(.name) | contains([$new_name])')
    if [ "${__exists:?}" = "true" ]; then
        __json=$(echo "${__json:?}" | jq --arg name_to_remove "${package_name:?}" '.apps |= map(select(.name != $name_to_remove))')
    fi

    # Download an icon image
    ensure_icon_exists "${package_name,,}" "${package_icon_url:?}"
    local __package_icon_path="${USER_HOME:?}/.local/share/icons/hicolor/256x256/apps/${package_name,,}.png"

    # Generate updated JSON for Sunshine's app.json file
    __updated_json=$(echo "$__json" | jq \
        --arg package_name "${package_name:?}" \
        --arg new_cmd "${__exec_cmd:?}" \
        --arg package_icon_path "${__package_icon_path:?}" \
        --arg working_dir "${USER_HOME:?}" \
        '.apps += [{
            "name": $package_name,
            "output": "",
            "cmd": "",
            "detached": [
                $new_cmd
            ],
            "exclude-global-prep-cmd": "false",
            "elevated": "false",
            "image-path": $package_icon_path,
            "working-dir": $working_dir
    }]')

    # Override Sunshine's app.json config file
    echo "${__updated_json:?}" > "${USER_HOME:?}/.config/sunshine/apps.json"
}

function ensure_symlink {
    # Function to ensure a symlink points to a specified target path
    __target_path="${1}"    # Desired target path
    __link_path="${2}"      # Path of the symlink to be checked/created

    # Check if the symlink doesn't exist or if it doesn't point to the desired target
    if [ ! -L "${__link_path:?}" ] || [ "$(ls -l "${__link_path:?}" 2> /dev/null | awk '{print $NF}')" != "${__target_path:?}" ]; then
        # Remove the existing file (if it's a file)
        [ -f "${__link_path:?}" ] && rm -f "${__link_path:?}"
        # Remove the existing directory (if it's a directory)
        [ -d "${__link_path:?}" ] && rm -rf "${__link_path:?}"
        # Create a new symlink to the desired path
        ln -snf "${__target_path:?}" "${__link_path:?}"
    fi
}
