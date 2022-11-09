#!/bin/bash
bas="/opt/redeploy/"
cfg="${bas}/hooks.json"
cfgdir="${bas}/webhook.d"

echo '[
    ' > "${cfg}.tmp"
for i in $(find ${cfgdir} -type f -name '*.json')
do
    cat "$i" >> "${cfg}.tmp"
    echo ",
    
    " >> "${cfg}.tmp"
done
echo '
]' >> "${cfg}.tmp"

awk NF "${cfg}.tmp" > "${cfg}" # remove empty and whitespace lines
rm "${cfg}.tmp"
second_to_last_line=$(( $(wc -l "${cfg}" | cut -d' ' -f1) - 1 )) # should be my trailing comma
sed -i "${second_to_last_line}d" "${cfg}"

type -p jq &>/dev/null && cat "${cfg}" | jq
echo "Done"
