#!/bin/bash
read -p "Clone url: " git_url 
read -p "webhook secret" webhook_secret

if [[ -z "${git_url}" ]]
then
    exit "clone url not set!"
    exit 1
fi

sudo mkdir -p /opt/redeploy/.ssh
sudo mkdir -p /opt/redeploy/webhook.d
sudo mkdir -p /opt/redeploy/ceddy.d 

repo_name="$(basename ${git_url} .git)"
cfg="/opt/redeploy/repo.d/${repo_name}.repo"
sudo mkdir -p "$($dirname $cfg)"
bas="$(dirname $0)"

echo "Creating ${cfg}"
echo "repo_url=\"${git_url}\"" > "${cfg}" 
echo "repo_id=\"/opt/redeploy/.ssh/${repo_name}_id\"" >> "${cfg}"
echo "repo_fqdn=\"${repo_name}\"" >> "${cfg}"
echo "repo_webhook=\"${webhook_secret:-changeme}\"" >> "${cfg}"
source ${cfg}

if [[ ! -f "${repo_id}" ]]
then
    ssh-keygen -t ed25519 -C "${USER}@${repo_fqdn}" -N "" -f "${repo_id}"
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

cfg="/opt/redeploy/webhook.d/${repo_name}.json"
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
    echo "Deploying"
    "$(dirname $0)/redeploy.sh" --repo ${repo_name}
else
    echo "Creating repository"
    mkdir -p "${repo_path}"
    cd "${repo_path}"
    git init
    echo '.hugo_build.lock' >> .gitignore
    hugo new site "${repo_name}" -f yml # use yaml config
    GIT_SSH_COMMAND="ssh -i $repo_id -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no'" git -C "$repo_path/$repo_name" git submodule add --depth=1 https://github.com/adityatelange/hugo-PaperMod.git themes/PaperMod
    echo 'tag = v6.0' >> .gitmodules
    GIT_SSH_COMMAND="ssh -i $repo_id -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no'" git -C "$repo_path/$repo_name" git submodule update --init --recursive # needed when you reclone your repo (submodules may not get cloned automatically)
    git add --all
    git commit -m "initial commit"
    git remote set-url origin ${repo_url}
    GIT_SSH_COMMAND="ssh -i $repo_id -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no'" git -C "$repo_path/$repo_name" git push origin
fi
echo "Done"
