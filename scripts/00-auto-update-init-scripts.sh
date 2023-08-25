#!/usr/bin/env bash
###
# File: 00-auto-update-init-scripts.sh
# Project: scripts
# File Created: Friday, 25th August 2023 2:27:28 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 25th August 2023 2:32:46 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

set -euo pipefail

if [[ ! -d "${USER_HOME:?}/init.d/" ]]; then
    echo "Error: The target directory '${USER_HOME:?}/init.d/' does not exist."
    exit 1
fi

pushd "${USER_HOME:?}/init.d/" >/dev/null

su - default -c 'git checkout master && git pull origin master'

popd >/dev/null
