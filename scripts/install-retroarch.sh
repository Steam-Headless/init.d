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
    7z x "${__install_dir:?}/${package_name,,}-${__latest_package_version:?}-linux-x86_64.7z" -aoa
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
	"${__emulation_path:?}"/roms/{gb,gba,gbc,gc,genesis,mastersystem,n3ds,n64,neogeo,nes,ngp,ngpc,psp,saturn,sega32x,segacd,sg-1000,snes,wii,dreamcast} \
    "${__emulation_path:?}"/storage/retroarch/{cheats,shaders,config,saves,screenshots,states,system}

ensure_symlink "${__emulation_path:?}/storage/retroarch/cheats" "${__retroarch_home:?}/.config/retroarch/cheats"
ensure_symlink "${__emulation_path:?}/storage/retroarch/config" "${__retroarch_home:?}/.config/retroarch/config"
ensure_symlink "${__emulation_path:?}/storage/retroarch/saves" "${__retroarch_home:?}/.config/retroarch/saves"
ensure_symlink "${__emulation_path:?}/storage/retroarch/screenshots" "${__retroarch_home:?}/.config/retroarch/screenshots"
ensure_symlink "${__emulation_path:?}/storage/retroarch/states" "${__retroarch_home:?}/.config/retroarch/states"
ensure_symlink "${__emulation_path:?}/storage/retroarch/system" "${__retroarch_home:?}/.config/retroarch/system"
ensure_symlink "${__emulation_path:?}/storage/retroarch/shaders" "${__retroarch_home:?}/.config/retroarch/shaders"

# Generate a default config if missing
if [ ! -f "${__retroarch_home:?}/.config/retroarch/retroarch.cfg" ]; then
    cat << EOF > "${__retroarch_home:?}/.config/retroarch/retroarch.cfg"
assets_directory = "${__emulation_path:?}/storage/retroarch/assets"
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
savestate_auto_load = "false"
savestate_auto_save = "false"
system_directory = "${__emulation_path:?}/storage/retroarch/system"
video_driver = "vulkan"
video_fullscreen = "true"
EOF
fi

cat << 'EOF' > "${__emulation_path:?}/roms/gb/systeminfo.txt"
System name:
gb

Full system name:
Nintendo game Boy

Supported file extensions:
.bs .BS .cgb .CGB .dmg .DMG .gb .GB .gbc .GBC .sgb .SGB .sfc .SFC .smc .SMC .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/gambatte_libretro.so %ROM%

Platform (for scraping):
gb

Theme folder:
gb
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/gba/systeminfo.txt"
System name:
gba

Full system name:
Nintendo Game Boy Advance

Supported file extensions:
.agb .AGB .bin .BIN .cgb .CGB .dmg .DMG .gb .GB .gba .GBA .gbc .GBC .sgb .SGB .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/mgba_libretro.so %ROM%

Platform (for scraping):
gba

Theme folder:
gba
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/gbc/systeminfo.txt"
System name:
gbc

Full system name:
Nintendo Game Boy Color

Supported file extensions:
.bs .BS .cgb .CGB .dmg .DMG .gb .GB .gbc .GBC .sgb .SGB .sfc .SFC .smc .SMC .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/gambatte_libretro.so %ROM%

Platform (for scraping):
gbc

Theme folder:
gbc
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/gc/systeminfo.txt"
System name:
gc

Full system name:
Nintendo GameCube

Supported file extensions:
.ciso .CISO .dff .DFF .dol .DOL .elf .ELF .gcm .GCM .gcz .GCZ .iso .ISO .json .JSON .m3u .M3U .rvz .RVZ .tgc .TGC .wad .WAD .wbfs .WBFS .wia .WIA .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/dolphin_libretro.so %ROM%

Platform (for scraping):
gc

Theme folder:
gc
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/genesis/systeminfo.txt"
System name:
genesis

Full system name:
Sega Genesis

Supported file extensions:
.32x .32X .68k .68K .bin .BIN .bms .BMS .chd .CHD .cue .CUE .gen .GEN .gg .GG .iso .ISO .m3u .M3U .md .MD .mdx .MDX .sg .SG .sgd .SGD .smd .SMD .sms .SMS .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/genesis_plus_gx_libretro.so %ROM%

Platform (for scraping):
genesis

Theme folder:
genesis
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/mastersystem/systeminfo.txt"
System name:
mastersystem

Full system name:
Sega Master System

Supported file extensions:
.68k .68K .bin .BIN .bms .BMS .chd .CHD .col .COL .cue .CUE .gen .GEN .gg .GG .iso .ISO .m3u .M3U .md .MD .mdx .MDX .rom .ROM .sg .SG .sgd .SGD .smd .SMD .sms .SMS .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/genesis_plus_gx_libretro.so %ROM%

Platform (for scraping):
mastersystem

Theme folder:
mastersystem
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/n3ds/systeminfo.txt"
System name:
n3ds

Full system name:
Nintendo 3DS

Supported file extensions:
.3ds .3DS .3dsx .3DSX .app .APP .axf .AXF .cci .CCI .cxi .CXI .elf .ELF .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/citra_libretro.so %ROM%

Platform (for scraping):
n3ds

Theme folder:
n3ds
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/n64/systeminfo.txt"
System name:
n64

Full system name:
Nintendo 64

Supported file extensions:
.bin .BIN .d64 .D64 .n64 .N64 .ndd .NDD .u1 .U1 .v64 .V64 .z64 .Z64 .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/mupen64plus_next_libretro.so %ROM%

Platform (for scraping):
n64

Theme folder:
n64
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/neogeo/systeminfo.txt"
System name:
neogeo

Full system name:
SNK Neo Geo

Supported file extensions:
.7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/fbneo_libretro.so %ROM%

Platform (for scraping):
neogeo

Theme folder:
neogeo
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/nes/systeminfo.txt"
System name:
nes

Full system name:
Nintendo Entertainment System

Supported file extensions:
.3dsen .3DSEN .fds .FDS .nes .NES .unf .UNF .unif .UNIF .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/mesen_libretro.so %ROM%

Platform (for scraping):
nes

Theme folder:
nes
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/ngp/systeminfo.txt"
System name:
ngp

Full system name:
SNK Neo Geo Pocket

Supported file extensions:
.ngp .NGP .ngc .NGC .ngpc .NGPC .npc .NPC .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/mednafen_ngp_libretro.so %ROM%

Platform (for scraping):
ngp

Theme folder:
ngp
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/ngpc/systeminfo.txt"
System name:
ngpc

Full system name:
SNK Neo Geo Pocket Color

Supported file extensions:
.ngp .NGP .ngc .NGC .ngpc .NGPC .npc .NPC .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/mednafen_ngp_libretro.so %ROM%

Platform (for scraping):
ngpc

Theme folder:
ngpc
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/psp/systeminfo.txt"
System name:
psp

Full system name:
Sony PlayStation Portable

Supported file extensions:
.elf .ELF .iso .ISO .cso .CSO .prx .PRX .pbp .PBP .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/ppsspp_libretro.so %ROM%

Platform (for scraping):
psp

Theme folder:
psp
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/saturn/systeminfo.txt"
System name:
saturn

Full system name:
Sega Saturn

Supported file extensions:
.bin .BIN .ccd .CCD .chd .CHD .cue .CUE .iso .ISO .mds .MDS .toc .TOC .m3u .M3U .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/mednafen_saturn_libretro.so %ROM%

Platform (for scraping):
saturn

Theme folder:
saturn
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/sega32x/systeminfo.txt"
System name:
sega32x

Full system name:
Sega Mega Drive 32X

Supported file extensions:
.bin .BIN .gen .GEN .smd .SMD .md .MD .32x .32X .cue .CUE .iso .ISO .sms .SMS .68k .68K .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/picodrive_libretro.so %ROM%

Platform (for scraping):
sega32x

Theme folder:
sega32x
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/segacd/systeminfo.txt"
System name:
segacd

Full system name:
Sega CD

Supported file extensions:
.68k .68K .bin .BIN .bms .BMS .chd .CHD .cue .CUE .gen .GEN .gg .GG .iso .ISO .m3u .M3U .md .MD .mdx .MDX .sg .SG .sgd .SGD .smd .SMD .sms .SMS .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/genesis_plus_gx_libretro.so %ROM%

Platform (for scraping):
segacd

Theme folder:
segacd
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/sg-1000/systeminfo.txt"
System name:
sg-1000

Full system name:
Sega SG-1000

Supported file extensions:
.68k .68K .bin .BIN .bms .BMS .chd .CHD .cue .CUE .gen .GEN .gg .GG .iso .ISO .m3u .M3U .md .MD .mdx .MDX .sg .SG .sgd .SGD .smd .SMD .sms .SMS .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/genesis_plus_gx_libretro.so %ROM%

Platform (for scraping):
sg-1000

Theme folder:
sg-1000
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/snes/systeminfo.txt"
System name:
snes

Full system name:
Sega SG-1000

Supported file extensions:
.bin .BIN .bml .BML .bs .BS .bsx .BSX .dx2 .DX2 .fig .FIG .gd3 .GD3 .gd7 .GD7 .mgd .MGD .sfc .SFC .smc .SMC .st .ST .swc .SWC .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/snes9x_libretro.so %ROM%

Platform (for scraping):
snes

Theme folder:
snes
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/wii/systeminfo.txt"
System name:
wii

Full system name:
Nintendo Wii

Supported file extensions:
.ciso .CISO .dff .DFF .dol .DOL .elf .ELF .gcm .GCM .gcz .GCZ .iso .ISO .json .JSON .m3u .M3U .rvz .RVZ .tgc .TGC .wad .WAD .wbfs .WBFS .wia .WIA .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/dolphin_libretro.so %ROM%

Platform (for scraping):
wii

Theme folder:
wii
EOF

cat << 'EOF' > "${__emulation_path:?}/roms/dreamcast/systeminfo.txt"
System name:
dreamcast

Full system name:
Sega Dreamcast

Supported file extensions:
.chd .CHD .cdi .CDI .iso .ISO .elf .ELF .cue .CUE .gdi .GDI .lst .LST .dat .DAT .m3u .M3U .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/flycast_libretro.so %ROM%

Platform (for scraping):
dreamcast

Theme folder:
dreamcast
EOF

#if [ ! -f "${__emulation_path:?}/storage/retroarch/config/mGBA/mGBA.slangp" ]; then
#    cat << EOF > "${__emulation_path:?}/storage/retroarch/config/mGBA/mGBA.slangp"
##reference "../../shaders/shaders_slang/presets/xsoft+scalefx-level2aa+sharpsmoother.slangp"
#EOF
#fi

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.local/share/retroarch \
    "${__emulation_path:?}"/roms \
    "${__emulation_path:?}"/storage/retroarch

echo "DONE"
