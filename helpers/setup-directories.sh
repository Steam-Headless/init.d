#!/usr/bin/env bash
###
# File: setup-directories.sh
# Project: helpers
# File Created: Friday, 25th August 2023 3:26:03 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 11th September 2023 4:14:08 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

set -euo pipefail

# Setup base paths
mkdir -p "${USER_HOME:?}/Applications"
if [ $(id -u) -gt 0 ]; then
    echo "WARNING!  Unable to set ownership of '${USER_HOME:?}/Applications'. Executed as non-root user."
else
    chown -R ${PUID:?}:${PGID:?} "${USER_HOME:?}/Applications"
fi

mkdir -p "${USER_HOME:?}"/.cache/init.d/installed_packages
if [ $(id -u) -gt 0 ]; then
    echo "WARNING!  Unable to set ownership of '${USER_HOME:?}/Applications'. Executed as non-root user."
else
    chown -R ${PUID:?}:${PGID:?} "${USER_HOME:?}/.cache/init.d"
fi
