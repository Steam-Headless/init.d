# Remove previously added entries
cat ${sunshine_conf} | jq 'del(.apps[] | select(.output == "SH-run.txt"))' > /tmp/sunshine.json 
mv -f /tmp/sunshine.json ${sunshine_conf}