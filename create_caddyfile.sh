#!/bin/bash
if [[ "$(whoami)" != "root" ]]
then
	echo "Please execute as root" 
	exit 1
fi

echo ' ' > /etc/caddy/Caddyfile
for i in $(find /opt/redeploy/caddy.d -type f -name '*.caddyfile' -printf "%p ")
do
	cat "$i" >> /etc/caddy/Caddyfile
   	echo " " >> /etc/caddy/Caddyfile  
done
