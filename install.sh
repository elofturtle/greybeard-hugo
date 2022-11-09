#!/bin/bash

source "$(dirname $0)/common-lib.sh" || {
	echo "ERR Couldn't source common lib!";
	exit 1;
}

rootcheck

echo "Registered repos:"
find /opt/redeploy/repo.d/ -type f -name '*.repo' -print

read -p "Done running add-repo.sh? [y/n]"
while [[ "$REPLY" != "y" ]] && [[ "$REPLY" != "Y" ]]
do
	echo "Adding repo..."
    	$(dirname $0)/add-repo.sh
    	echo" "
    	echo "Repos:"
    	find "${bas}/repo.d/" -type f -name '*.repo' -print
    	read -p "Done running add-repo.sh? [y/n]"
done

##################
# Install things #
##################
install_git
install_caddy
install_webhook
install_hugo 0.105.0
install_redeploy

################################
# Set permissions after install#
################################
echo "Updating permissions"
update_permissions

echo "Generating caddyfile"
$(dirname $0)/create_caddyfile.sh

echo "Creating webhook config"
$(dirname $0)/create_webhook.sh

echo "Creating redeploy config"
update_redeploy_config

################
# SystemD stuff#
################
restorecon -R -v "${bas}"
restorecon -R -v  "${bin_dir}/" # fix selinux permission for webhook binary

echo "Restarting services (caddy, webhook)"
systemctl enable "${bas}/webhook.service"
systemctl enable caddy
systemctl restart caddy
systemctl status caddy --no-pager
systemctl restart webhook
systemctl status webhook --no-pager

echo "Done"
