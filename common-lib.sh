export bas="/opt/redeploy"
export www_target="/var/www"
export repo_base="/tmp/repos"
export bin_dir="/usr/bin"
export caddy_user="caddy"

function install_git {
	type git &>/dev/null && echo "git already installed" || {
		echo "Installing git";
		dnf -y install git;
	}
}

function install_caddy {
	type caddy &>/dev/null && echo "caddy already installed" || {
		echo "Installing caddy";
		dnf -y install 'dnf-command(copr)';
		dnf -y copr enable @caddy/caddy;
		dnf -y install caddy;
	}
}

function install_webhook {
	type webhook &>/dev/null && echo "webhook already installed" || {
		wget "https://github.com/adnanh/webhook/releases/latest/download/webhook-linux-amd64.tar.gz -O /tmp/webhook.tar.gz";
        	tar -C "${bin_dir}/" -xvf "/tmp/webhook.tar.gz" --strip-components=1;
        	chmod +x "${bin_dir}/webhook";
		cp "$(dirname $0)/webhook.service" "${bas}/";
	}
}

function install_hugo {
	type hugo &>/dev/null && echo "hugo already installed" || {
		wget "https://github.com/gohugoio/hugo/releases/download/v${1:-0.0.0}/hugo_${1:-0.0.0}_Linux-64bit.tar.gz" -O "/tmp/hugo.tar.gz";
        	tar -C "${bin_dir}/" -xvf "/tmp/hugo.tar.gz" "hugo";
        	chmod +x "${bin_dir}/hugo";
	}
}

function install_redeploy {
	[[ -f "${bas}/redeploy.sh" ]] && echo "redeploy.sh already installed" || {
		cp "$(dirname $0)/redeploy.sh" "${bas}/redeploy.sh" ;
        	chmod +x "${bas}/redeploy.sh";
	}
}

function get_site_config {
        if [[ -z "$www_target" ]]
        then
                source "$bas/redeploy.conf"
        fi
        if [[ ! -f "$1" ]]
        then
                :
        else
                source "$1"
                repo_path="$www_target/$(tr '.' $'\n' <<< "$repo_fqdn" | tac | paste -s -d '/')"
                if [[ -z "$sender" ]]
                then
                        sender="${2:-admin@${repo_fqdn}}"
                fi

                echo "${repo_fqdn} {
                        root * ${repo_path}
                        file_server
                        tls ${sender}
                }"
        fi
}

function rootcheck {
	if [[ "$(whoami)" != "root" ]]
	then
		echo "Please execute as root"
		exit 1
	fi
}

function update_permissions {
	mkdir -p $"{www_target}"
	chown -R ${caddy_user}:root "${www_target}"
	chown -R ${caddy_user}:root "${repo_base}"
	mkdir -p ${bas}/.ssh
	mkdir -p ${bas}/webhook.d
}

function update_redeploy_config {
	echo '# explicitly define binaries because systemd
caddy_bin="$(type -p caddy)"
caddy_user="${caddy_user}"
git_bin="$(type -p git)"
webhook_bin="$(type -p webhook)"
www_target="${www_target}"   # generated sites here
repo_base="${repo_base}"  # clone repos here
' > "${bas}/redeploy.conf"
}

# Always end with this - do we want to define distro specific functions?
release=$(cat /etc/os-release | grep ^ID= | cut -d '=' -f2 | tr -d '"')
case "$release" in
        ubuntu*|debian*) 
		source $(dirname $0)/ubuntu-lib.sh
                ;;
        *) 
		: # don't overload anything, just use common lib.
                ;;
esac
