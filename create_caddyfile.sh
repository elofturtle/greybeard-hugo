#!/usr/bin/env bash
bas="$(dirname $(readlink -f $0))"
source "${bas}/redeploy.conf" || {
	echo "ERR failed source config!";
	exit 1;
}

if [[ "$(whoami)" != "root" ]]
then
    echo "Please execute as root"
    exit 1
fi

function get_site_config {
    repo_fqdn=$(basename $1 .repo)
    repo_path="${www_target}/$(tr '.' $'\n' <<< "${repo_fqdn}" | tac | paste -s -d '/')/${repo_fqdn}" # /var/www/se/osninja/osninja.se

    echo "${repo_fqdn}:443 {
            root * ${repo_path}
            file_server
            tls $(cat ${ssh_key_dir}/${repo_fqdn}_id.pub | cut -d' ' -f3)
    }

    ${repo_fqdn}:80 {
            redir https://${repo_fqdn} 302
            tls $(cat ${ssh_key_dir}/${repo_fqdn}_id.pub | cut -d' ' -f3)
    }
    "
}

cfg="/etc/caddy/Caddyfile"
cp "${cfg}" "${cfg}.old"

echo ' ' > "${cfg}.tmp"
for i in $(find "$repo_dir" -type f -name '*.repo' -printf "%p ")
do
	get_site_config "$i" >> "${cfg}.tmp"
   	echo " " >> "${cfg}.tmp"
done

mv "${cfg}.tmp" "${cfg}"

systemctl restart caddy