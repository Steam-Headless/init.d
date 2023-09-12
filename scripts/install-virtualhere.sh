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
package_icon_url=""
package_executable=""
package_category="Utility"
print_package_name


# Check for a new version to install
__latest_package_version=""
__latest_package_id=""
__latest_package_url="https://www.virtualhere.com/sites/default/files/usbserver/vhusbdx86_64"
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"



echo "DONE"
