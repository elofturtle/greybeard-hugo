#!/usr/bin/env bash
git_url="$1"
webhook_secret="$2"

if [[ -z "$git_url" ]]
then
	read -p "Clone url: " git_url 
fi
if [[ -z "$webhook_secret" ]] 
then
	read -p "Webhook secret: " webhook_secret
fi

if [[ -z "${git_url}" ]]
then
    exit "clone url not set!"
    exit 1
fi

sudo mkdir -p /opt/redeploy/{.ssh,webhook.d,caddy.d,repo.d}


repo_name="$(basename ${git_url} .git)"
cfg="/opt/redeploy/repo.d/${repo_name}.repo"
bas="$(dirname $(readlink -f $0))"

echo "Creating ${cfg}"
echo "repo_url=\"${git_url}\"" > "${cfg}" 
echo "repo_id=\"/opt/redeploy/.ssh/${repo_name}_id\"" >> "${cfg}"
echo "repo_fqdn=\"${repo_name}\"" >> "${cfg}"
echo "repo_webhook=\"${webhook_secret:-changeme}\"" >> "${cfg}"
source ${cfg}

if [[ ! -f "${repo_id}" ]]
then
    ssh-keygen -t ed25519 -C "${sender}@${repo_fqdn}" -N "" -f "${repo_id}"
fi
echo "Public key (deployment key for Github)"
cat "${repo_id}.pub"

echo " "
echo "Följ instruktioner för att sätta upp en [Github webhook](https://docs.github.com/en/developers/webhooks-and-events/webhooks/creating-webhooks)."
echo "Låt hemligheten vara ${repo_webhook} (samma som för din webhook)."
echo " "

cfg="/opt/redeploy/webhook.d/${repo_name}.json"
echo "Creating ${cfg}"
cp "$bas/webhook.json.orig" "${cfg}"
sed -i "s/REPO_NAME/${repo_name}/g" "${cfg}"
sed -i "s/changeme/${webhook_secret}/g" "${cfg}"

cfg="/opt/redeploy/caddy.d/${repo_name}.caddyfile"
repo_path="/var/www/$(tr '.' $'\n' <<< "$repo_fqdn" | tac | paste -s -d '/')"
echo "Creating ${cfg}"
echo "${repo_fqdn} {
        root * ${repo_path}
        file_server
        tls ${sender:-admin}@${repo_fqdn}
}" > "${cfg}"

read -p "Initialize repo [y/n]? "
if [[ $REPLY != "y" ]] && [[ $REPLY != "Y" ]]
then
	:
else
    echo "Creating repository"
    repo_path="/tmp/repos/${repo_name}"
    mkdir -p "${repo_path}"
    cd "$(dirname ${repo_path})"
    hugo new site "${repo_name}" -f yml # use yaml config
    cd "${repo_path}"
    git init
    git config user.email ${sender:-admin}@${repo_fqdn}
    git config user.username ${sender:-admin}
    echo '.hugo_build.lock' >> .gitignore
    
    GIT_SSH_COMMAND="ssh -i $repo_id -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no'" git -C "$repo_path" submodule add --depth=1 https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
    echo 'tag = v6.0' >> .gitmodules
    GIT_SSH_COMMAND="ssh -i $repo_id -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no'" git -C "$repo_path"  submodule update --init --recursive # needed when you reclone your repo (submodules may not get cloned automatically)
    git add --all
    git commit -m "initial commit"
    git remote add origin ${repo_url}
    read -p "Push (you must have configured a push key yourself)? "
    if [[ "$REPLY" == "y" ]] || [[ "$REPLY" == "Y" ]]
    then
	    GIT_SSH_COMMAND="ssh -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no'" git -C "$repo_path"  push origin master $(git -C "$repo_path" git rev-parse --abbrev-ref HEAD)
    fi
fi
echo "Done"
