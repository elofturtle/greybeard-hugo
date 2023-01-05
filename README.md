# greybeard-hugo
Hjälpskript för att sätta upp Hugo (på Centos Stream 9). 

# Steg-för-steg-guide
Kör skripten från repo-rooten för säkerhets skull.
* Kör add-repo.sh ett antal gånger. Det skapar upp ett antal pseudo-konfigurationer i /opt/redeploy.
* Kör sedan install.sh

TODO: verifiera att allt funkar som det ska på tom maskin :)

# Använda Hugo

TODO: enkel guide och länkar
TODO: extend repo conf to support more templates for webhooks
TODO: use install instead of cp to set modes immediately
TODO: integrate uninstall.sh, create*, add-repo.sh to common libs and move into install.sh. rename to just install and redeploy and fix vim lang

# Manuell installation av förkrav (server)

## Installera git (versionshanterare)
### Centos
```bash
type git &>/dev/null && echo "git already installed" || {
    echo "Installing git";
    sudo dnf -y install git;
}
```

### Ubuntu
```bash
type git &>/dev/null && echo "git already installed" || {
    echo "Installing git";
    sudo apt -y install git;
}
```

## Installera Caddy (webbserver)

### Centos
```bash
type caddy &>/dev/null && echo "caddy already installed" || {
    echo "Installing caddy";
    sudo dnf -y install 'dnf-command(copr)';
    sudo dnf -y copr enable @caddy/caddy;
    sudo dnf -y install caddy;
}
```

### Ubuntu
```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
sudo curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
sudo curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update -y
sudo apt  install -y caddy
```

## Installera jq (valfritt)

### Centos
```bash
sudo dnf install -y jq
```

### Ubuntu
```bash
sudo apt install -y jq
```

## Installera Hugo (webbplatsgenerator)
```bash
type hugo &>/dev/null && echo "hugo already installed" || {
    wget "https://github.com/gohugoio/hugo/releases/download/v${hugo_version:-1.0.5}/hugo_${hugo_version:-1.0.5}_Linux-64bit.tar.gz" -O "/tmp/hugo.tar.gz";
    sudo tar -C "/usr/bin/" -xvf "/tmp/hugo.tar.gz" "hugo";
    sudo chmod +x "/usr/bin/hugo";
}
```

# Installera installationsskript (detta repo)
```bash
sudo git clone git@github.com:elofturtle/greybeard-hugo.git /opt/redeploy
sudo chmod +x /opt/redeploy/*.sh
```

# konfigurationer

## Uppdatera redeploy.conf
```bash
vim /opt/redeploy/redeploy.conf # all relevant konfig läses härifrån
```
Minst delarna hörande till webhook måste justeras.

Detta steg måste göras innan övriga konfiguration.

## Skapa filer för repon
Två saker behövs för varje repo.
En fil i repo_dir (/opt/redeploy/repo.d) med samma namn som domänen.
Domänen och repot antas ha samma namn.
Internationella domännamn måste konverteras först (se t.ex. https://idnconvert.se/ ).

```bash
# /opt/redeploy/repo.d/example.com.repo
repo_url=git@github.com:johndoe/example.com.git
```

URL:en används både för att skapa konfiguration för caddy och för att lyssna efter uppdateringar från en webhook.

Skapa en ssh-nyckel (läsaccess) eller länka till en existerande nyckel så att namnet blir rätt.

```bash
ssh-keygen -t ed25519 -C "<recipient>@<your domain>" -N "" -f "/opt/redeploy/repo.d/example.com_id"
cat "/opt/redeploy/repo.d/example.com_id.pub"
```

Följ instruktioner för att sätta upp en [Github webhook](https://docs.github.com/en/developers/webhooks-and-events/webhooks/creating-webhooks)."

Låt hemligheten vara det som du angav i redeploy.conf.

Iyp application/json".

Webhook url http://${webhook_domain}/postreceive/github (mathcar id:t i regeln).

## Genererade filer
```bash
sudo /opt/redeploy/create_webhook.sh
sudo /opt/redeploy/create_caddyfile.sh
sudo chown -R caddy:root /opt/redeploy/
sudo chown -R caddy:root /var/www/
```
## DNS
Dina domännamn måste peka på rätt server (eller lastbalanserare för att ACME-protokollet ska fungera automagiskt med Caddy.

## Systemd
```bash
restorecon -R -v "/var/www"
restorecon -R -v "/opt/redeploy"
restorecon -R -v  "/usr/bin/" # fix selinux permission for webhook binary
systemctl enable "/opt/redeploy/webhook.service"
systemctl enable caddy
systemctl restart caddy
systemctl status caddy --no-pager
systemctl restart webhook
systemctl status webhook --no-pager
```
# Sätta upp ett nytt Hugo-repo (med exempel)
TODO
