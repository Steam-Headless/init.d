#!/usr/bin/env bash
###
# File: install-virtualhere.sh
# Project: scripts
# File Created: Monday, 11th September 2023 3:57:47 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 11th September 2023 8:08:55 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install VirtualHere Server during container startup.
#   You will need a license to pass more than one device over USB over IP
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/install-virtualhere.sh" "${USER_HOME:?}/init.d/install-virtualhere.sh"
#
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"

# Ensure this script is being executed as the default user
exec_script_as_default_user

# Config
package_name="VirtualHere"
package_description="The server-side component of VirtualHere"
package_executable="${USER_HOME:?}/.local/bin/${package_name:?}"
package_category="Utility"
print_package_name


# Check for a new version to install
__latest_package_url="https://www.virtualhere.com/sites/default/files/usbserver/vhusbdx86_64"
print_step_header "Latest ${package_name:?}"

if ([ ! -f "${package_executable:?}" ] || [ ! -f "/tmp/.user-script-${package_name,,}-installed" ]); then
    # Download Server
    print_step_header "Downloading ${package_name:?}"
    wget -O "${USER_HOME:?}/.local/bin/${package_name,,}" \
        --quiet -o /dev/null \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        "${__latest_package_url:?}"
    chmod +x ${USER_HOME:?}/.local/bin/${package_name,,}
	
    # Mark this version as installed
    touch "/tmp/.user-script-${package_name,,}-installed"
else
    print_step_header "${package_name:?} already installed"
fi

print_step_header "Enabeling ${package_name:?} supervisor unit"
# Setup virtualhere supervised
if [ ! -f "/etc/supervisor.d/virtualhere.ini" ]; then
    cat << EOF > "/tmp/virtualhere.ini"
[program:virtualhere]
priority=99
autostart=true
autorestart=true
startretries=50
user=root
directory=${USER_HOME:?}/.local/bin
command=${USER_HOME:?}/.local/bin/virtualhere
environment=
stopsignal=INT
stdout_logfile=/home/%(ENV_USER)s/.cache/log/virtualhere.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=7
stderr_logfile=/home/%(ENV_USER)s/.cache/log/virtualhere.err.log
stderr_logfile_maxbytes=10MB
stderr_logfile_backups=7
EOF

sudo cp -v /tmp/virtualhere.ini /etc/supervisor.d/virtualhere.ini
rm /tmp/virtualhere.ini
fi

sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start virtualhere

echo "DONE"
