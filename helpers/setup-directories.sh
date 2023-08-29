#!/usr/bin/env bash
###
# File: setup-directories.sh
# Project: helpers
# File Created: Friday, 25th August 2023 3:26:03 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 25th August 2023 4:25:11 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

set -euo pipefail

# Setup base paths
mkdir -p "${USER_HOME:?}/Applications"
chown -R ${PUID:?}:${PGID:?} "${USER_HOME:?}/Applications"

mkdir -p "${USER_HOME:?}"/.cache/init.d/{installed_packages,package_icons}
chown -R ${PUID:?}:${PGID:?} "${USER_HOME:?}"/.cache/init.d
