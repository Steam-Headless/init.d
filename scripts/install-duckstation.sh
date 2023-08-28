#!/usr/bin/env bash
###
# File: install-duckstation.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 27th August 2023 10:52:09 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install Duckstation during container startup.
#   This will also configure duckstation with some default options for Steam Headless.
#   It will also configure the duckstation AppImage as the default emulator for GBA ROMs in ES-DE.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "${USER_HOME:?}/init.d/scripts/install-duckstation.sh" "${USER_HOME:?}/init.d/install-duckstation.sh"
#
###


# Config
package_name="duckstation-qt"
package_description="Playstation Emulator"
package_icon_url="https://cdn2.steamgriddb.com/file/sgdb-cdn/icon/e1f581b9f9af4ca9be996aa40da6759e/32/24x24.png"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"
package_icon="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"


source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
source "${USER_HOME:?}/init.d/helpers/functions.sh"
source "${USER_HOME:?}/init.d/helpers/functions-es-de-config.sh"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/stenzek/duckstation/releases/latest)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.tag_name')
__latest_package_id=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.id')
__latest_package_url=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.browser_download_url')
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"


# Only install if the latest version does not already exist locally
if [ ! -f "${package_executable:?}" ] || [ ! -f "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}" ]; then
    # Download Appimage to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    fetch_appimage_and_make_executable "${__latest_package_url:?}"

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu short is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    touch "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}"
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi


# Generate duckstation Emulation directory structure
romsPath="/mnt/games/Emulation/roms"
biosPath="/mnt/games/Emulation/bios"
savesPath="/mnt/games/Emulation/saves"
storagePath="/mnt/games/Emulation/storage"
mkdir -p \
    "${USER_HOME:?}"/.local/share/duckstation \
    "${savesPath:?}"/duckstation/states \
    "${savesPath:?}"/duckstation/memcards \
    "${biosPath:?}"/duckstation \
    "${storagePath:?}"/duckstation/screenshots \
    "${storagePath:?}"/duckstation/covers \
    "${storagePath:?}"/duckstation/cache \
    "${romsPath:?}"/psx

# Generate a default config if missing
if [ ! -f "${USER_HOME:?}/.local/share/duckstation/settings.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.local/share/duckstation/settings.ini"
[Main]
SettingsVersion = 3
EmulationSpeed = 1
FastForwardSpeed = 0
TurboSpeed = 0
SyncToHostRefreshRate = false
IncreaseTimerResolution = true
InhibitScreensaver = true
StartPaused = false
StartFullscreen = false
PauseOnFocusLoss = false
PauseOnMenu = true
SaveStateOnExit = true
CreateSaveStateBackups = true
CompressSaveStates = true
ConfirmPowerOff = true
LoadDevicesFromSaveStates = true
ApplyCompatibilitySettings = true
ApplyGameSettings = true
AutoLoadCheats = true
DisableAllEnhancements = false
RewindEnable = false
RewindFrequency = 10
RewindSaveSlots = 10
RunaheadFrameCount = 0
EnableDiscordPresence = false


[ControllerPorts]
ControllerSettingsMigrated = true
MultitapMode = Disabled
PointerXScale = 8
PointerYScale = 8
PointerXInvert = false
PointerYInvert = false


[Console]
Region = Auto
Enable8MBRAM = false


[CPU]
ExecutionMode = Recompiler
OverclockEnable = false
OverclockNumerator = 1
OverclockDenominator = 1
RecompilerMemoryExceptions = false
RecompilerBlockLinking = true
RecompilerICache = false
FastmemMode = MMap


[GPU]
Renderer = Vulkan
Adapter = 
ResolutionScale = 5
Multisamples = 1
UseDebugDevice = false
PerSampleShading = false
UseThread = true
ThreadedPresentation = true
UseSoftwareRendererForReadbacks = false
TrueColor = true
ScaledDithering = true
TextureFilter = xBR
DownsampleMode = Disabled
DisableInterlacing = true
ForceNTSCTimings = false
WidescreenHack = false
ChromaSmoothing24Bit = false
PGXPEnable = true
PGXPCulling = true
PGXPTextureCorrection = true
PGXPColorCorrection = false
PGXPVertexCache = false
PGXPCPU = false
PGXPPreserveProjFP = false
PGXPTolerance = -1
PGXPDepthBuffer = false
PGXPDepthClearThreshold = 300


[Display]
CropMode = Overscan
ActiveStartOffset = 0
ActiveEndOffset = 0
LineStartOffset = 0
LineEndOffset = 0
Force4_3For24Bit = false
AspectRatio = Auto (Game Native)
Alignment = Center
CustomAspectRatioNumerator = 0
LinearFiltering = true
IntegerScaling = false
Stretch = false
PostProcessing = false
ShowOSDMessages = true
ShowFPS = false
ShowSpeed = false
ShowResolution = false
ShowCPU = false
ShowGPU = false
ShowFrameTimes = false
ShowStatusIndicators = true
ShowInputs = false
ShowEnhancements = false
DisplayAllFrames = false
InternalResolutionScreenshots = false
StretchVertically = false
VSync = false
MaxFPS = 0
OSDScale = 100


[CDROM]
ReadaheadSectors = 8
RegionCheck = false
LoadImageToRAM = false
LoadImagePatches = false
MuteCDAudio = false
ReadSpeedup = 1
SeekSpeedup = 1


[Audio]
Backend = Cubeb
Driver = 
OutputDevice = 
StretchMode = TimeStretch
BufferMS = 50
OutputLatencyMS = 20
OutputVolume = 100
FastForwardVolume = 100
OutputMuted = false
DumpOnBoot = false


[Hacks]
UseOldMDECRoutines = false
DMAMaxSliceTicks = 1000
DMAHaltTicks = 100
GPUFIFOSize = 16
GPUMaxRunAhead = 128


[PCDrv]
Enabled = false
EnableWrites = false
Root = 


[BIOS]
PatchTTYEnable = false
PatchFastBoot = false
SearchDirectory = ${biosPath:?}/duckstation/


[MemoryCards]
Card1Type = PerGameTitle
Card2Type = None
UsePlaylistTitle = true
Directory = ${savesPath:?}/duckstation/memcards 
Card2Path = ${savesPath:?}/duckstation/memcards/shared_card_2.mcd
Card1Path = ${savesPath:?}/duckstation/memcards/shared_card_1.mcd


[Cheevos]
Enabled = false
TestMode = false
UnofficialTestMode = false
UseFirstDiscFromPlaylist = true
RichPresence = true
ChallengeMode = false
Leaderboards = true
Notifications = true
SoundEffects = true
PrimedIndicators = true


[Logging]
LogLevel = Info
LogFilter = 
LogToConsole = true
LogToDebug = false
LogToWindow = false
LogToFile = false


[Debug]
ShowVRAM = false
DumpCPUToVRAMCopies = false
DumpVRAMToCPUCopies = false
ShowGPUState = false
ShowCDROMState = false
ShowSPUState = false
ShowTimersState = false
ShowMDECState = false
ShowDMAState = false


[TextureReplacements]
EnableVRAMWriteReplacements = false
PreloadTextures = false
DumpVRAMWrites = false
DumpVRAMWriteForceAlphaChannel = true
DumpVRAMWriteWidthThreshold = 128
DumpVRAMWriteHeightThreshold = 128


[Folders]
Cache = ${storagePath:?}/duckstation//mnt/games/Emulation/storage/duckstation/cache
Cheats = cheats
Covers = ${storagePath:?}/duckstation//mnt/games/Emulation/storage/duckstation/covers
Dumps = dump
GameSettings = gamesettings
InputProfiles = inputprofiles
SaveStates = ${savesPath:?}/duckstation/states
Screenshots = ${storagePath:?}/duckstation//mnt/games/Emulation/storage/duckstation/screenshots
Shaders = shaders
Textures = textures


[InputSources]
SDL = true
SDLControllerEnhancedMode = false
Evdev = false
XInput = false
RawInput = false


[Pad1]
Type = AnalogController
Up = Keyboard/Up
Right = Keyboard/Right
Down = Keyboard/Down
Left = Keyboard/Left
Triangle = Keyboard/I
Circle = Keyboard/L
Cross = Keyboard/K
Square = Keyboard/J
Select = Keyboard/Backspace
Start = Keyboard/Return
L1 = Keyboard/Q
R1 = Keyboard/E
L2 = Keyboard/1
R2 = Keyboard/3
L3 = Keyboard/2
R3 = Keyboard/4
LLeft = Keyboard/A
LRight = Keyboard/D
LDown = Keyboard/S
LUp = Keyboard/W
RLeft = Keyboard/F
RRight = Keyboard/H
RDown = Keyboard/G
RUp = Keyboard/T


[Pad2]
Type = None


[Pad3]
Type = None


[Pad4]
Type = None


[Pad5]
Type = None


[Pad6]
Type = None


[Pad7]
Type = None


[Pad8]
Type = None


[Hotkeys]
FastForward = Keyboard/Tab
TogglePause = Keyboard/Space
Screenshot = Keyboard/F10
ToggleFullscreen = Keyboard/F11
OpenPauseMenu = Keyboard/Escape
LoadSelectedSaveState = Keyboard/F1
SaveSelectedSaveState = Keyboard/F2
SelectPreviousSaveStateSlot = Keyboard/F3
SelectNextSaveStateSlot = Keyboard/F4


[GameList]
RecursivePaths = ${romsPath:?}/psx


[UI]
MainWindowGeometry = AdnQywADAAAAAARWAAABhwAAB38AAAQ3AAAEWwAAAaQAAAd6AAAEMgAAAAAAAAAAB4AAAARbAAABpAAAB3oAAAQy
EOF
fi

# Configure EmulationStation DE
cat << 'EOF' > "${romsPath:?}/psx/systeminfo.txt"
System name:
psx

Full system name:
Sony Playstation

Supported file extensions:
.cue .CUE .chd .CHD .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_DUCKSTATION% -batch %ROM%

Alternative launch commands:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/mednafen_psx_libretro.so %ROM%
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/mednafen_psx_hw_libretro.so %ROM%
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/pcsx_rearmed_libretro.so %ROM%
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/swanstation_libretro.so %ROM%
%EMULATOR_MEDNAFEN% -force_module psx %ROM%

Platform (for scraping):
psx

Theme folder:
psx
EOF
if ! grep -ri "psx:" "${romsPath:?}/systems.txt" &>/dev/null; then
    print_step_header "Adding 'psx' path to '${romsPath:?}/systems.txt'"
    echo "psx: " >> "${romsPath:?}/systems.txt"
    chown -R ${PUID:?}:${PGID:?} "${romsPath:?}/systems.txt"
fi
sed -i 's|^psx:.*$|psx: Sony Playstation|' "${romsPath:?}/systems.txt"
ensure_esde_alternative_emulator_configured "psx" "DuckStation (Standalone)"

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.local/share/duckstation \
    "${savesPath:?}"/duckstation/states \
    "${savesPath:?}"/duckstation/memcards \
    "${biosPath:?}"/duckstation \
    "${storagePath:?}"/duckstation/screenshots \
    "${storagePath:?}"/duckstation/covers \
    "${storagePath:?}"/duckstation/cache \
    "${romsPath:?}"/psx \
    "${USER_HOME:?}"/.emulationstation

echo "DONE"
