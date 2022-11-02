#!/bin/bash
read -p "Done running add-repo.sh? [y/n]"
if [[ "$REPLY" != "y" ]] || [[ "$REPLY" != "Y" ]]
then
    echo "exiting prematurely"
    exit 1
fi

echo "Installing git"
sudo dnf -y install git

echo "Installing Caddy"
sudo dnf -y install 'dnf-command(copr)'
sudo dnf copr enable @caddy/caddy
sudo dnf -y install caddy # /etc/caddy/Caddyfile
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