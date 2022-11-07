#!/bin/bash 
if [[ "$(whoami)" != "root" ]]
then
	echo "Please execute as root"
	exit 1
fi

read -p "Complete removal[y/n]? "
if [[ "$REPLY" == y ]] || [[ "$REPLY" == "Y" ]]
then
	rm -rfv /opt/redeploy/
else
	rm -rfv /opt/redeploy/redeploy.sh
fi

sleep 1
systemctl stop caddy
systemctl disable caddy
rm -rfv /usr/bin/caddy

sleep 1
systemctl stop webhook
systemctl disable webhook
rm -rfv /usr/bin/webhook

sleep 1
rm -rfv /usr/bin/hugo

echo "Uninstall complete"
