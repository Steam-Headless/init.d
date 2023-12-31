#!/usr/bin/env bash
###
# File: install-pegasus.sh
# Project: scripts
# File Created: Saturday, 16th September 2023 7:05:31 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 17th September 2023 4:21:08 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install Pegasus during container startup.
#   It will also configure an entry into Sunshine's apps.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/install-pegasus.sh" "${USER_HOME:?}/init.d/install-pegasus.sh"
#
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


# Config
package_name="Pegasus"
package_description="A cross platform, customizable graphical frontend for launching emulators and managing your game collection."
package_icon_url="https://pegasus-frontend.org/img/logo-700.png"
package_executable=""
package_category="Game"
print_package_name

if [ ! -f "/tmp/.user-script-${package_name,,}-installed" ]; then
    print_step_header "Install ${package_name:?} from Flathub"
    flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 
    flatpak --user install --assumeyes --or-update org.pegasus_frontend.Pegasus

    # Mark this package as installed
    touch "/tmp/.user-script-${package_name,,}-installed"
fi

# Configure Sunshine entry
print_step_header "Adding sunshine entry for ${package_name:?}"
ensure_sunshine_detached_command_entry "/usr/bin/sunshine-run /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=/app/bin/pegasus-fe org.pegasus_frontend.Pegasus"
