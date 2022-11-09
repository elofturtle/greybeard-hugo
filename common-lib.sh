export bas="/opt/redeploy"

function install_git {
	dnf -y install git
}

function install_caddy {
	dnf -y install 'dnf-command(copr)'
	dnf -y copr enable @caddy/caddy
	dnf -y install caddy
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
