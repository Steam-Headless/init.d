#!/usr/bin/env bash
###
# File: configure-yuzu.sh
# Project: scripts
# File Created: Friday, 25th August 2023 7:27:26 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Wednesday, 30th August 2023 12:33:59 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###

source "${USER_HOME:?}/init.d/helpers/functions.sh"

# Generate Yuzu Emulation directory structure
__emulation_path="/mnt/games/Emulation"
mkdir -p \
    "${USER_HOME:?}"/.local/share/yuzu \
    "${__emulation_path:?}/storage/yuzu"/{dump,keys,load,nand,screenshots,sdmc,tas,firmware}

# Create relative symlinks from the BIOS paths to Yuzu storage
mkdir -p "${__emulation_path:?}/storage/yuzu/nand/system/Contents/registered"
touch "${__emulation_path:?}/storage/yuzu/nand/system/Contents/registered/putfirmwarehere.txt"
ensure_symlink "../../../storage/yuzu/nand/system/Contents/registered" "${__emulation_path:?}/storage/yuzu/firmware"
if [ ! -f "${__emulation_path:?}/storage/yuzu/keys/putkeyshere.txt" ]; then
    echo "Place both 'title.keys' and 'prod.keys' files here." > "${__emulation_path:?}/storage/yuzu/keys/putkeyshere.txt"
fi

# Create absolute symlinks from the ~/.local/share/yuzu/ directories to our storage path
ensure_symlink "${__emulation_path:?}/storage/yuzu/dump" "${USER_HOME:?}/.local/share/yuzu/dump"
ensure_symlink "${__emulation_path:?}/storage/yuzu/keys" "${USER_HOME:?}/.local/share/yuzu/keys"
ensure_symlink "${__emulation_path:?}/storage/yuzu/load" "${USER_HOME:?}/.local/share/yuzu/load"
ensure_symlink "${__emulation_path:?}/storage/yuzu/nand" "${USER_HOME:?}/.local/share/yuzu/nand"
ensure_symlink "${__emulation_path:?}/storage/yuzu/screenshots" "${USER_HOME:?}/.local/share/yuzu/screenshots"
ensure_symlink "${__emulation_path:?}/storage/yuzu/sdmc" "${USER_HOME:?}/.local/share/yuzu/sdmc"
ensure_symlink "${__emulation_path:?}/storage/yuzu/tas" "${USER_HOME:?}/.local/share/yuzu/tas"

# Install default Yuzu config
mkdir -p "${USER_HOME:?}/.config/yuzu"
if [ ! -f "${USER_HOME:?}/.config/yuzu/qt-config.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.config/yuzu/qt-config.ini"

[Data%20Storage]
dump_directory=${__emulation_path:?}/storage/yuzu/dump
load_directory=${__emulation_path:?}/storage/yuzu/load
nand_directory=${__emulation_path:?}/storage/yuzu/nand
sdmc_directory=${__emulation_path:?}/storage/yuzu/sdmc
tas_directory=${__emulation_path:?}/storage/yuzu/tas

[Renderer]
resolution_setup=2
resolution_setup\default=true

[UI]
Paths\gamedirs\1\deep_scan=false
Paths\gamedirs\1\deep_scan\default=true
Paths\gamedirs\1\expanded=true
Paths\gamedirs\1\expanded\default=true
Paths\gamedirs\1\path=SDMC
Paths\gamedirs\2\deep_scan=false
Paths\gamedirs\2\deep_scan\default=true
Paths\gamedirs\2\expanded=true
Paths\gamedirs\2\expanded\default=true
Paths\gamedirs\2\path=UserNAND
Paths\gamedirs\3\deep_scan=false
Paths\gamedirs\3\deep_scan\default=true
Paths\gamedirs\3\expanded=true
Paths\gamedirs\3\expanded\default=true
Paths\gamedirs\3\path=SysNAND
Paths\gamedirs\4\deep_scan=false
Paths\gamedirs\4\deep_scan\default=true
Paths\gamedirs\4\expanded=true
Paths\gamedirs\4\expanded\default=true
Paths\gamedirs\4\path=${__emulation_path:?}/roms/switch
Paths\gamedirs\size=4

Screenshots\enable_screenshot_save_as=true
Screenshots\enable_screenshot_save_as\default=true
Screenshots\screenshot_path=${__emulation_path:?}/storage/yuzu/screenshots

Shortcuts\Main%20Window\Audio%20Mute\Unmute\Context=1
Shortcuts\Main%20Window\Audio%20Mute\Unmute\Context\default=true
Shortcuts\Main%20Window\Audio%20Mute\Unmute\Controller_KeySeq=
Shortcuts\Main%20Window\Audio%20Mute\Unmute\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Audio%20Volume%20Down\Controller_KeySeq=
Shortcuts\Main%20Window\Audio%20Volume%20Down\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Audio%20Volume%20Up\Controller_KeySeq=
Shortcuts\Main%20Window\Audio%20Volume%20Up\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Capture%20Screenshot\Controller_KeySeq=
Shortcuts\Main%20Window\Capture%20Screenshot\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Change%20Adapting%20Filter\Controller_KeySeq=Plus+Dpad_Left
Shortcuts\Main%20Window\Change%20Adapting%20Filter\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Change%20Docked%20Mode\Controller_KeySeq=Plus+Dpad_Up
Shortcuts\Main%20Window\Change%20Docked%20Mode\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Change%20GPU%20Accuracy\Controller_KeySeq=Plus+Dpad_Down
Shortcuts\Main%20Window\Change%20GPU%20Accuracy\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Continue\Pause%20Emulation\Controller_KeySeq=Minus+A
Shortcuts\Main%20Window\Continue\Pause%20Emulation\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Exit%20Fullscreen\Controller_KeySeq=
Shortcuts\Main%20Window\Exit%20Fullscreen\Controller_KeySeq\default=true
Shortcuts\Main%20Window\Exit%20Fullscreen\KeySeq=Esc
Shortcuts\Main%20Window\Exit%20Fullscreen\KeySeq\default=true
Shortcuts\Main%20Window\Exit%20yuzu\Context=1
Shortcuts\Main%20Window\Exit%20yuzu\Context\default=true
Shortcuts\Main%20Window\Exit%20yuzu\Controller_KeySeq=Minus+X
Shortcuts\Main%20Window\Exit%20yuzu\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Exit%20yuzu\KeySeq=Ctrl+Q
Shortcuts\Main%20Window\Exit%20yuzu\KeySeq\default=true
Shortcuts\Main%20Window\Fullscreen\Context=1
Shortcuts\Main%20Window\Fullscreen\Context\default=true
Shortcuts\Main%20Window\Fullscreen\Controller_KeySeq=Minus+Right_Stick
Shortcuts\Main%20Window\Fullscreen\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Fullscreen\KeySeq=F11
Shortcuts\Main%20Window\Fullscreen\KeySeq\default=true
Shortcuts\Main%20Window\Load%20File\Context=3
Shortcuts\Main%20Window\Load%20File\Context\default=true
Shortcuts\Main%20Window\Load%20File\Controller_KeySeq=
Shortcuts\Main%20Window\Load%20File\Controller_KeySeq\default=true
Shortcuts\Main%20Window\Load%20File\KeySeq=Ctrl+O
Shortcuts\Main%20Window\Load%20File\KeySeq\default=true
Shortcuts\Main%20Window\Load\Remove%20Amiibo\Context=3
Shortcuts\Main%20Window\Load\Remove%20Amiibo\Context\default=true
Shortcuts\Main%20Window\Load\Remove%20Amiibo\Controller_KeySeq=
Shortcuts\Main%20Window\Load\Remove%20Amiibo\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Load\Remove%20Amiibo\KeySeq=F2
Shortcuts\Main%20Window\Load\Remove%20Amiibo\KeySeq\default=true
Shortcuts\Main%20Window\Restart%20Emulation\Context=1
Shortcuts\Main%20Window\Restart%20Emulation\Context\default=true
Shortcuts\Main%20Window\Restart%20Emulation\Controller_KeySeq=
Shortcuts\Main%20Window\Restart%20Emulation\Controller_KeySeq\default=true
Shortcuts\Main%20Window\Restart%20Emulation\KeySeq=F6
Shortcuts\Main%20Window\Restart%20Emulation\KeySeq\default=true
Shortcuts\Main%20Window\Stop%20Emulation\Context=1
Shortcuts\Main%20Window\Stop%20Emulation\Context\default=true
Shortcuts\Main%20Window\Stop%20Emulation\Controller_KeySeq=
Shortcuts\Main%20Window\Stop%20Emulation\Controller_KeySeq\default=true
Shortcuts\Main%20Window\Stop%20Emulation\KeySeq=F5
Shortcuts\Main%20Window\Stop%20Emulation\KeySeq\default=true
Shortcuts\Main%20Window\TAS%20Record\Context=2
Shortcuts\Main%20Window\TAS%20Record\Context\default=true
Shortcuts\Main%20Window\TAS%20Record\Controller_KeySeq=
Shortcuts\Main%20Window\TAS%20Record\Controller_KeySeq\default=true
Shortcuts\Main%20Window\TAS%20Record\KeySeq=Ctrl+F7
Shortcuts\Main%20Window\TAS%20Record\KeySeq\default=true
Shortcuts\Main%20Window\TAS%20Reset\Context=2
Shortcuts\Main%20Window\TAS%20Reset\Context\default=true
Shortcuts\Main%20Window\TAS%20Reset\Controller_KeySeq=
Shortcuts\Main%20Window\TAS%20Reset\Controller_KeySeq\default=true
Shortcuts\Main%20Window\TAS%20Reset\KeySeq=Ctrl+F6
Shortcuts\Main%20Window\TAS%20Reset\KeySeq\default=true
Shortcuts\Main%20Window\TAS%20Start\Stop\Context=2
Shortcuts\Main%20Window\TAS%20Start\Stop\Context\default=true
Shortcuts\Main%20Window\TAS%20Start\Stop\Controller_KeySeq=
Shortcuts\Main%20Window\TAS%20Start\Stop\Controller_KeySeq\default=true
Shortcuts\Main%20Window\TAS%20Start\Stop\KeySeq=Ctrl+F5
Shortcuts\Main%20Window\TAS%20Start\Stop\KeySeq\default=true
Shortcuts\Main%20Window\Toggle%20Filter%20Bar\Context=1
Shortcuts\Main%20Window\Toggle%20Filter%20Bar\Context\default=true
Shortcuts\Main%20Window\Toggle%20Filter%20Bar\Controller_KeySeq=
Shortcuts\Main%20Window\Toggle%20Filter%20Bar\Controller_KeySeq\default=true
Shortcuts\Main%20Window\Toggle%20Filter%20Bar\KeySeq=Ctrl+F
Shortcuts\Main%20Window\Toggle%20Filter%20Bar\KeySeq\default=true
Shortcuts\Main%20Window\Toggle%20Framerate%20Limit\Context=2
Shortcuts\Main%20Window\Toggle%20Framerate%20Limit\Context\default=true
Shortcuts\Main%20Window\Toggle%20Framerate%20Limit\Controller_KeySeq=Minus+ZR
Shortcuts\Main%20Window\Toggle%20Framerate%20Limit\Controller_KeySeq\default=false
Shortcuts\Main%20Window\Toggle%20Framerate%20Limit\KeySeq=Ctrl+U
Shortcuts\Main%20Window\Toggle%20Framerate%20Limit\KeySeq\default=true
Shortcuts\Main%20Window\Toggle%20Mouse%20Panning\Context=2
Shortcuts\Main%20Window\Toggle%20Mouse%20Panning\Context\default=true
Shortcuts\Main%20Window\Toggle%20Mouse%20Panning\Controller_KeySeq=
Shortcuts\Main%20Window\Toggle%20Mouse%20Panning\Controller_KeySeq\default=true
Shortcuts\Main%20Window\Toggle%20Mouse%20Panning\KeySeq=Ctrl+F9
Shortcuts\Main%20Window\Toggle%20Mouse%20Panning\KeySeq\default=true
Shortcuts\Main%20Window\Toggle%20Status%20Bar\Context=1
Shortcuts\Main%20Window\Toggle%20Status%20Bar\Context\default=true
Shortcuts\Main%20Window\Toggle%20Status%20Bar\Controller_KeySeq=
Shortcuts\Main%20Window\Toggle%20Status%20Bar\Controller_KeySeq\default=true
Shortcuts\Main%20Window\Toggle%20Status%20Bar\KeySeq=Ctrl+S
Shortcuts\Main%20Window\Toggle%20Status%20Bar\KeySeq\default=true
Shortcuts\Main%20Window\Toggle%20Status%20Bar\Repeat=false
Shortcuts\Main%20Window\Toggle%20Status%20Bar\Repeat\default=true

fullscreen=true
fullscreen\default=false

calloutFlags=1
calloutFlags\default=false

confirmClose=false
confirmClose\default=false

firstStart=false
firstStart\default=false

[WebService]
enable_telemetry=false
enable_telemetry\default=false

EOF
fi

# Configure EmulationStation DE
mkdir -p "${__emulation_path:?}/roms/switch"
cat << 'EOF' > "${__emulation_path:?}/roms/switch/systeminfo.txt"
System name:
switch

Full system name:
Nintendo Switch

Supported file extensions:
.nca .NCA .nro .NRO .nso .NSO .nsp .NSP .xci .XCI .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_YUZU% -f -g %ROM%

Alternative launch command:
%EMULATOR_RYUJINX% %ROM%

Platform (for scraping):
switch

Theme folder:
switch
EOF
if ! grep -ri "switch:" "${__emulation_path:?}/roms/systems.txt" &>/dev/null; then
    print_step_header "Adding 'switch' path to '${__emulation_path:?}/roms/systems.txt'"
    echo "switch: " >> "${__emulation_path:?}/roms/systems.txt"
    chown -R ${PUID:?}:${PGID:?} "${__emulation_path:?}/roms/systems.txt"
fi
sed -i 's|^switch:.*$|switch: Nintendo Switch|' "${__emulation_path:?}/roms/systems.txt"

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.local/share/yuzu \
    "${USER_HOME:?}"/.config/yuzu \
    "${__emulation_path:?}/roms/switch" \
    "${__emulation_path:?}/storage/yuzu"
