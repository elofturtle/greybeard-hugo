#!/bin/bash
bas="/opt/redeploy/"
cfg="${bas}/hooks.json"
cfgdir="${bas}/webhook.d"

echo '[
    ' > "${cfg}"
for i in $(find ${cfgdir} -type f -name '*.json')
do
    cat "$i" >> "${cfg}"
    echo ",
    
    " >> "${cfg}"
done
echo '
]' >> "${cfg}"
sed -i 's/\(.*\),/\1/' "${cfg}" # hopefully remove trailing ',' in list

echo "Done"
