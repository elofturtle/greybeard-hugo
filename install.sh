#!/bin/bash
if [[ "$(whoami)" != "root" ]]
then
	echo "Please execute as root"
	exit 0
fi

echo "Registered repos:"
find /opt/redeploy/repo.d/ -type f -name '*.repo' -print
read -p "Done running add-repo.sh? [y/n]"
while [[ "$REPLY" != "y" ]] && [[ "$REPLY" != "Y" ]]
do
	echo "Adding repo..."
    	$(dirname $0)/add-repo.sh
    	echo" "
    	echo "Repos:"
    	find /opt/redeploy/repo.d/ -type f -name '*.repo' -print
    	read -p "Done running add-repo.sh? [y/n]"
done

if [[ ! -f "/usr/bin/git" ]]
then
	echo "Installing git"
	dnf -y install git
else
	echo "Skipping git install"
fi

if [[ ! -f "/usr/bin/caddy" ]]
then
	echo "Installing Caddy"
	dnf -y install 'dnf-command(copr)'
	dnf -y copr enable @caddy/caddy
	dnf -y install caddy # /etc/caddy/Caddyfile
	systemctl enable caddy
else
	echo "Skipping caddy install"
fi
echo "Generating caddyfile"
$(dirname $0)/create_caddyfile.sh

echo "Updating permissions"
mkdir -p /var/www/
chown -R caddy:root /var/www/ 
chown -R caddy:root /tmp/repos/


if [[ ! -f "/usr/bin/webhook" ]]
then
	echo "Install webhook"
	wget https://github.com/adnanh/webhook/releases/latest/download/webhook-linux-amd64.tar.gz -O /tmp/webhook.tar.gz
	tar -C /usr/bin/ -xvf /tmp/webhook.tar.gz --strip-components=1
	chmod +x /usr/bin/webhook
else
	echo "Skipping webhook install"
fi
echo "Updating permissions"
mkdir -p /opt/redeploy/.ssh
mkdir -p /opt/redeploy/webhook.d
restorecon -R -v  /usr/bin/ # fix selinux permission for webhook binary
cp webhook.service /opt/redeploy/
systemctl enable /opt/redeploy/webhook.service

echo "Creating webhook config"
$(dirname $0)/create_webhook.sh

if [[ ! -f "/usr/bin/hugo" ]]
then
	echo "Install hugo"
	wget https://github.com/gohugoio/hugo/releases/download/v${hugo_version:-0.105.0}/hugo_${hugo_version:-0.105.0}_Linux-64bit.tar.gz -O /tmp/hugo.tar.gz
	tar -C /usr/bin/ -xvf /tmp/hugo.tar.gz hugo
	chmod +x /usr/bin/hugo
else
	echo "Skipping hugo install"
fi

if [[ ! -f "/opt/redeploy/redeploy.sh" ]]
then
	echo "Install redeploy.sh"
	cp redeploy.sh /opt/redeploy/redeploy.sh 
	chmod +x /opt/redeploy/redeploy.sh
	echo '
# explicitly define binaries because systemd
caddy_bin="/usr/bin/caddy"
caddy_user="caddy"
git_bin="/usr/bin/git"
webhook_bin="/usr/bin/webhook"
www_target="/var/www"   # generated sites here
repo_base="/tmp/repos"  # clone repos here
' > /opt/redeploy/redeploy.conf
	restorecon -R -v /opt/redeploy
else
	echo "Skipping redeploy.sh install"
fi
echo "Restarting services (caddy, webhook)"
systemctl restart caddy
systemctl status caddy --no-pager
systemctl restart webhook
systemctl status webhook --no-pager

echo "Done"
