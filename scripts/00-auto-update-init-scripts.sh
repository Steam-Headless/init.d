#!/usr/bin/env bash
###
# File: 00-auto-update-init-scripts.sh
# Project: scripts
# File Created: Friday, 25th August 2023 2:27:28 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 11th September 2023 7:44:15 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Automatically pull the latest changes from the https://github.com/Steam-Headless/init.d/.
#   NOTE: This is prefixed with `00-` in order to ensure it is run before any other scripts.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/00-auto-update-init-scripts.sh" "${USER_HOME:?}/init.d/00-auto-update-init-scripts.sh"
#
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


if [[ ! -d "${USER_HOME:?}/init.d/" ]]; then
    echo "Error: The target directory '${USER_HOME:?}/init.d/' does not exist."
    exit 1
fi

cd "${USER_HOME:?}/init.d/" && git checkout . && git checkout master && git pull origin master

echo "DONE"
