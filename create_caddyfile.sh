#!/bin/bash
source "$(dirname $0)/common-lib.sh" || {
	echo "ERR failed source common libs!";
	exit 1;
}

rootcheck

cfg="/etc/caddy/Caddyfile"

echo ' ' > "$cfg"
for i in $(find "$bas/repo.d" -type f -name '*.repo' -printf "%p ")
do
	get_site_config "$i" >> "$cfg"
   	echo " " >> "$cfg"  
done

sudo systemctl restart caddy
