#!/bin/bash

function centos_install_git {
	sudo dnf -y install git
}

# Extend this and create corresponding distro-lib.sh file, implementing the functions defined in centos-lib.sh to create support for other distros.
release=$(cat /etc/os-release | grep ^ID= | cut -d '=' -f2 | tr -d '"')
case "$release" in 
	centos*|fedora*|rhel*) source $(dirname $0)/centos-lib.sh
		;;
	ubuntu*|debian*) source $(dirname $0)/ubuntu-lib.sh
		;;
	*) echo "ERR Can't guess ditro!" && exit 1
		;;
esac

read -p "Done running add-repo.sh? [y/n]"
if [[ "$REPLY" != "y" ]] || [[ "$REPLY" != "Y" ]]
then
    echo "exiting prematurely"
    exit 1
fi

echo "Installing git"
install_git

echo "Installing Caddy"
install_caddy # /etc/caddy/Caddyfile
sudo systemctl enable caddy
sudo $(dirname $0)/create_caddyfile.sh

sudo mkdir -p /var/www/
sudo chown -R caddy:root /var/www/ 


echo "Install webhook"
wget https://github.com/adnanh/webhook/releases/latest/download/webhook-linux-amd64.tar.gz -O /tmp/webhook.tar.gz
sudo tar -C /usr/bin/ -xvf /tmp/webhook.tar.gz --strip-components=1
sudo chmod +x /usr/bin/webhook
sudo mkdir -p /opt/redeploy/.ssh
sudo mkdir -p /opt/redeploy/webhook.d
sudo restorecon -R -v  /usr/bin/ # fix selinux permission for webhhok binary
sudo cp webhook.service /opt/redeploy/
sudo systemctl enable /opt/redeploy/webhook.service
sudo $(dirname $0)/create_webhook.sh

echo "Install hugo"
wget https://github.com/gohugoio/hugo/releases/download/v${hugo_version:-0.105.0}/hugo_${hugo_version:-0.105.0}_Linux-64bit.tar.gz -O /tmp/hugo.tar.gz
sudo tar -C /usr/bin/ -xvf /tmp/hugo.tar.gz hugo
sudo chmod +x /usr/bin/hugo

echo "Install redeploy.sh"
sudo cp redeploy.sh /opt/redeploy/redeploy.sh 
sudo chmod +x /opt/redeploy/redeploy.sh
sudo echo '
# explicitly define binaries because systemd
caddy_bin="/usr/bin/caddy"
caddy_user="caddy"
git_bin="/usr/bin/git"
webhook_bin="/usr/bin/webhook"
www_target="/var/www"   # generated sites here
repo_base="/tmp/repos"  # clone repos here
' > /opt/redeploy/redeploy.conf

sudo systemctl start caddy
sudo systemctl status caddy
sudo systemctl start webhook
sudo systemctl status webhook

echo "Done"
