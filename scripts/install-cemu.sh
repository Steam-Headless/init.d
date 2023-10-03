#!/usr/bin/env bash
###
# File: install-cemu.sh
# Project: scripts
# File Created: Saturday, 2nd September 2023 11:08:22 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 17th September 2023 4:26:21 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install Cemu during container startup.
#   This will also configure Cemu with some default options for Steam Headless.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/install-cemu.sh" "${USER_HOME:?}/init.d/install-cemu.sh"
#
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


# Config
package_name="Cemu"
package_description="Nintendo Wii U Emulator"
package_icon_url="https://upload.wikimedia.org/wikipedia/commons/2/25/Cemu_Emulator_icon.png"
package_executable="${USER_HOME:?}/Applications/${package_name,,}.AppImage"
package_category="Game"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/cemu-project/Cemu/releases | jq 'sort_by(.published_at) | .[-1]')
__latest_package_version=$(echo "${__registry_package_json:?}" | jq -r '.tag_name')
__latest_package_id=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith(".AppImage")) | .id' | head -n 1)
__latest_package_url=$(echo "${__registry_package_json:?}" | jq -r '.assets[] | select(.name | endswith(".AppImage")) | .browser_download_url' | head -n 1)
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"
__installed_version=$(catalog -g ${package_name,,})


# Only install if the latest version does not already exist locally
if ([ ! -f "${package_executable:?}" ] || [ "${__installed_version:-X}" != "${__latest_package_version:?}" ]); then
    # Download Appimage to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    fetch_appimage_and_make_executable "${__latest_package_url:?}"

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu shortcut is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    catalog -s ${package_name,,} ${__latest_package_version:?}
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi


# Generate Cemu Emulation directory structure
__emulation_path="/mnt/games/Emulation"
mkdir -p \
    "${USER_HOME:?}"/.local/share/Cemu \
    "${USER_HOME:?}"/.config/Cemu \
    "${__emulation_path:?}/bios/cemu" \
    "${__emulation_path:?}/storage/cemu"/{keys,memorySearcher,mlc01}

# Create relative symlinks from the Keys paths in Cemu storage
ensure_symlink "../../storage/cemu/keys" "${__emulation_path:?}/bios/cemu/keys"
ensure_symlink "${__emulation_path:?}/storage/cemu/keys/keys.txt" "${USER_HOME:?}/.local/share/Cemu/keys.txt"
# Create base keys.txt file
if [ ! -f "${__emulation_path:?}/storage/cemu/keys/keys.txt" ]; then
    cat << EOF > "${__emulation_path:?}/storage/cemu/keys/keys.txt"
# this file contains keys needed for decryption of disc file system data (WUD/WUX)
# 1 key per line, any text after a '#' character is considered a comment
# the emulator will automatically pick the right key
541b9889519b27d363cd21604b97c67a # example key (can be deleted)
EOF
fi

# Create absolute symlinks from the ~/.local/share/Cemu/ directories to our storage path
ensure_symlink "${__emulation_path:?}/storage/cemu/mlc01" "${USER_HOME:?}/.local/share/Cemu/mlc01"

# Install default Cemu config
if [ ! -f "${USER_HOME:?}/.config/Cemu/settings.xml" ]; then
    cat << EOF > "${USER_HOME:?}/.config/Cemu/settings.xml"
<?xml version="1.0" encoding="UTF-8"?>
<content>
    <logflag>0</logflag>
    <advanced_ppc_logging>false</advanced_ppc_logging>
    <mlc_path>/mnt/games/Emulation/storage/cemu/mlc01</mlc_path>
    <permanent_storage>true</permanent_storage>
    <language>0</language>
    <use_discord_presence>false</use_discord_presence>
    <fullscreen_menubar>true</fullscreen_menubar>
    <feral_gamemode>false</feral_gamemode>
    <check_update>false</check_update>
    <save_screenshot>true</save_screenshot>
    <vk_warning>false</vk_warning>
    <gp_download>true</gp_download>
    <macos_disclaimer>false</macos_disclaimer>
    <fullscreen>false</fullscreen>
    <proxy_server></proxy_server>
    <disable_screensaver>true</disable_screensaver>
    <console_language>1</console_language>
    <window_position>
        <x>-1</x>
        <y>-1</y>
    </window_position>
    <window_size>
        <x>-1</x>
        <y>-1</y>
    </window_size>
    <window_maximized>false</window_maximized>
    <open_pad>false</open_pad>
    <pad_position>
        <x>0</x>
        <y>0</y>
    </pad_position>
    <pad_size>
        <x>0</x>
        <y>0</y>
    </pad_size>
    <pad_maximized>false</pad_maximized>
    <GameList>
        <style>0</style>
        <order>{0, 1, 2, 3, 4, 5, 6, 7}</order>
        <name_width>500</name_width>
        <version_width>60</version_width>
        <dlc_width>50</dlc_width>
        <game_time_width>140</game_time_width>
        <game_started_width>160</game_started_width>
        <region_width>306</region_width>
        <title_id>0</title_id>
    </GameList>
    <RecentLaunchFiles/>
    <RecentNFCFiles/>
    <GamePaths>
        <Entry>/mnt/games/Emulation/roms/wiiu</Entry>
    </GamePaths>
    <GameCache/>
    <GraphicPack/>
    <Graphic>
        <api>1</api>
        <device></device>
        <VSync>0</VSync>
        <GX2DrawdoneSync>true</GX2DrawdoneSync>
        <UpscaleFilter>0</UpscaleFilter>
        <DownscaleFilter>0</DownscaleFilter>
        <FullscreenScaling>0</FullscreenScaling>
        <AsyncCompile>true</AsyncCompile>
        <vkAccurateBarriers>true</vkAccurateBarriers>
        <Overlay>
            <Position>0</Position>
            <TextColor>4294967295</TextColor>
            <TextScale>100</TextScale>
            <FPS>false</FPS>
            <DrawCalls>false</DrawCalls>
            <CPUUsage>false</CPUUsage>
            <CPUPerCoreUsage>false</CPUPerCoreUsage>
            <RAMUsage>false</RAMUsage>
            <VRAMUsage>false</VRAMUsage>
            <Debug>false</Debug>
        </Overlay>
        <Notification>
            <Position>1</Position>
            <TextColor>4294967295</TextColor>
            <TextScale>100</TextScale>
            <ControllerProfiles>false</ControllerProfiles>
            <ControllerBattery>false</ControllerBattery>
            <ShaderCompiling>false</ShaderCompiling>
            <FriendService>false</FriendService>
        </Notification>
    </Graphic>
    <Audio>
        <api>3</api>
        <delay>2</delay>
        <TVChannels>1</TVChannels>
        <PadChannels>1</PadChannels>
        <InputChannels>0</InputChannels>
        <TVVolume>50</TVVolume>
        <PadVolume>0</PadVolume>
        <InputVolume>50</InputVolume>
        <TVDevice></TVDevice>
        <PadDevice></PadDevice>
        <InputDevice></InputDevice>
    </Audio>
    <Account>
        <PersistentId>2147483649</PersistentId>
        <OnlineEnabled>false</OnlineEnabled>
        <ActiveService>0</ActiveService>
    </Account>
    <Debug>
        <CrashDumpUnix>0</CrashDumpUnix>
        <GDBPort>1337</GDBPort>
    </Debug>
    <Input>
        <DSUC host="127.0.0.1" port="26760"/>
    </Input>
</content>
EOF
fi
if [ ! -f "${USER_HOME:?}/.config/Cemu/settings.xml" ]; then
    cat << EOF > "${USER_HOME:?}/.config/Cemu/settings.xml"
<?xml version="1.0" encoding="UTF-8"?>
<emulated_controller>
        <type>Wii U GamePad</type>
        <controller>
                <api>SDLController</api>
                <uuid>0_030003f05e0400008e02000010010000</uuid>
                <display_name>X360 Controller</display_name>
                <rumble>0</rumble>
                <axis>
                        <deadzone>0.25</deadzone>
                        <range>1</range>
                </axis>
                <rotation>
                        <deadzone>0.25</deadzone>
                        <range>1</range>
                </rotation>
                <trigger>
                        <deadzone>0.25</deadzone>
                        <range>1</range>
                </trigger>
                <mappings>
                        <entry>
                                <mapping>24</mapping>
                                <button>40</button>
                        </entry>
                        <entry>
                                <mapping>23</mapping>
                                <button>46</button>
                        </entry>
                        <entry>
                                <mapping>22</mapping>
                                <button>41</button>
                        </entry>
                        <entry>
                                <mapping>21</mapping>
                                <button>47</button>
                        </entry>
                        <entry>
                                <mapping>20</mapping>
                                <button>38</button>
                        </entry>
                        <entry>
                                <mapping>19</mapping>
                                <button>44</button>
                        </entry>
                        <entry>
                                <mapping>18</mapping>
                                <button>39</button>
                        </entry>
                        <entry>
                                <mapping>17</mapping>
                                <button>45</button>
                        </entry>
                        <entry>
                                <mapping>16</mapping>
                                <button>8</button>
                        </entry>
                        <entry>
                                <mapping>15</mapping>
                                <button>7</button>
                        </entry>
                        <entry>
                                <mapping>14</mapping>
                                <button>14</button>
                        </entry>
                        <entry>
                                <mapping>1</mapping>
                                <button>0</button>
                        </entry>
                        <entry>
                                <mapping>2</mapping>
                                <button>1</button>
                        </entry>
                        <entry>
                                <mapping>3</mapping>
                                <button>2</button>
                        </entry>
                        <entry>
                                <mapping>4</mapping>
                                <button>3</button>
                        </entry>
                        <entry>
                                <mapping>5</mapping>
                                <button>9</button>
                        </entry>
                        <entry>
                                <mapping>6</mapping>
                                <button>10</button>
                        </entry>
                        <entry>
                                <mapping>7</mapping>
                                <button>42</button>
                        </entry>
                        <entry>
                                <mapping>8</mapping>
                                <button>43</button>
                        </entry>
                        <entry>
                                <mapping>9</mapping>
                                <button>6</button>
                        </entry>
                        <entry>
                                <mapping>10</mapping>
                                <button>4</button>
                        </entry>
                        <entry>
                                <mapping>11</mapping>
                                <button>11</button>
                        </entry>
                        <entry>
                                <mapping>12</mapping>
                                <button>12</button>
                        </entry>
                        <entry>
                                <mapping>13</mapping>
                                <button>13</button>
                        </entry>
                </mappings>
        </controller>
</emulated_controller>
EOF
fi

# Configure EmulationStation DE
mkdir -p "${__emulation_path:?}/roms/wiiu"
cat << 'EOF' > "${__emulation_path:?}/roms/wiiu/systeminfo.txt"
System name:
wiiu (custom system)

Full system name:
Nintendo Wii U

Supported file extensions:
.rpx .RPX .wud .WUD .wux .WUX .elf .ELF .iso .ISO .wad .WAD .wua .WUA

Launch command:
/usr/bin/bash /run/media/external/Emulation/tools/launchers/cemu.sh -f -g z:%ROM%

Platform (for scraping):
wiiu

Theme folder:
wiiu
EOF
if ! grep -ri "wiiu:" "${__emulation_path:?}/roms/systems.txt" &>/dev/null; then
    print_step_header "Adding 'wiiu' path to '${__emulation_path:?}/roms/systems.txt'"
    echo "wiiu: " >> "${__emulation_path:?}/roms/systems.txt"
fi
sed -i 's|^wiiu:.*$|wiiu: Nintendo Wii U|' "${__emulation_path:?}/roms/systems.txt"

echo "DONE"
