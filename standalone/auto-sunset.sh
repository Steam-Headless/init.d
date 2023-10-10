# Remove previously added entries
sunshine_conf=${USER_HOME:?}/.config/sunshine/apps.json

cat ${sunshine_conf} | jq 'del(.apps[] | select(.output == "SH-run.txt"))' > /tmp/sunshine.json 
mv -f /tmp/sunshine.json ${sunshine_conf}