#!/usr/bin/env bash
###
# File: functions-es-de-config.sh
# Project: helpers
# File Created: Monday, 28th August 2023 11:35:55 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 11th September 2023 4:12:55 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

function ensure_esde_alternative_emulator_configured {
    __console_id=${1}
    __alternative_emulator_label=${@:2}
    __xml_file="${USER_HOME:?}/.emulationstation/gamelists/${__console_id:?}/gamelist.xml"

    # Check if the alternativeEmulator element exists
    if [ -f "${__xml_file:?}" ]; then
        # Check if alternativeEmulator exists in the file
        if grep -q '<alternativeEmulator>' "${__xml_file:?}"; then
            # Use sed to replace the content if alternativeEmulator exists
            sed -i "\#<alternativeEmulator>#,\#</alternativeEmulator>#c\<alternativeEmulator>\n\t<label>${__alternative_emulator_label:?}<\/label>\n<\/alternativeEmulator>" "${__xml_file:?}"
        else
            # Generate a base file if not already configured
            if ! grep -q '<gameList>' "${__xml_file:?}"; then
                echo '<?xml version="1.0"?>' > "${__xml_file:?}"
                echo '<gameList></gameList>' >> "${__xml_file:?}"
            fi
            # Add alternativeEmulator block if it doesn't exist
            sed -i "s#<gameList>#<alternativeEmulator>\n\t<label>${__alternative_emulator_label:?}<\/label>\n<\/alternativeEmulator>\n<gameList>#" "${__xml_file:?}"
        fi
    else
        mkdir -p "$(dirname ${__xml_file:?})"
        set_default_user_ownership "$(dirname ${__xml_file:?})"
        cat << EOF > "${__xml_file:?}"
<?xml version="1.0"?>
<alternativeEmulator>
	<label>${__alternative_emulator_label:?}</label>
</alternativeEmulator>
<gameList>
</gameList>
EOF
    fi
}
