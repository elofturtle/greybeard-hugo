#!/bin/bash
sudo echo ' ' > /etc/caddy/Caddyfile
for i in $(find /opt/redeploy/webhook.d -type f -name '*.json')
do
    sudo cat "$i
    " >> /etc/caddy/Caddyfile 
done