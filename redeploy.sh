#!/usr/bin/env bash
# webhook -urlprefix postreceive  -hooks hooks.json -verbose
bas="$(dirname $0)"
konf="${bas}/$(basename $0 .sh).conf"
clean_repo="false"

function verify_init {
        if [[ -z "$1" ]]
        then
                echo "$2"
                exit "$3"
        fi
        return 0 
}

function update_path {
        verify_init "$1" "$2" "$3"
        if [[ ! -f "$1" ]]
        then
                echo "$1 defined but not found!"
                exit "$3"
        else
                export PATH="$(dirname $1):$PATH"
        fi
        return 0
}

while (($#))
do
        case $1 in
                '--config')
                        shift
                        konf="$(readlink -f $1)"
                        ;;
                '--clean')
                        clean_repo="true"
                        ;;
                '--repo')
                        shift
                        repo="$1"
                        ;;
                '--repo-list')
                        find "$bas/repo.d" -type f -name '*.repo' -exec basename {} .repo \;
                        exit 0
                        ;;
                '--help'|*)
                        echo "$(basename $0):"
                        echo "  --clean         delete repo and clone again"
                        echo "  --repo          which repo config to use?"
                        echo "  --config        config file to use"
                        echo "  --repo-list     list repos that have configuration"
                        echo "  --help          print this and exit"
                        echo
                        exit 0
                        ;;
        esac
        shift
done

verify_init "$bas" "bas not defined" "1"
verify_init "$clean_repo" "clean_repo not set" "5"
verify_init "$konf" "konf not defined" "2"
source "${konf}" || {
        echo "${konf} not found or unreadable";
        exit "3";
}

update_path "$caddy_bin" "caddy_bin not defined" "10"
update_path "$git_bin" "git_bin not defined" "12"
update_path "$webhook_bin" "webhook_bin not defined" "13"

verify_init "$caddy_user" "caddy_user not defined" "11"
verify_init "$www_target" "www_target not defined" "14"

verify_init "$repo" "Repo not defined" "4"
source "${bas}/repo.d/${repo}.repo" || {
        echo "${bas}/repo.d/${repo}.repo not found or unreadable";
        exit 6;
}

verify_init "$repo_base" "repo_base not defined" "15"

verify_init "$repo_url" "repo_url (git clone uri) not defined" "17"
verify_init "$repo_id" "repo_id (ssh key path) not defined" "18"
verify_init "$repo_fqdn" "repo_fqdn not defined" "19"

repo_path="$repo_base/$(tr '.' $'\n' <<< "$repo_fqdn" | tac | paste -s -d '/')" # /tmp/repos/eu/feks
repo_name="$(basename $repo_path)"                                              # feks
repo_path="$(dirname $repo_path)"                                               # /tmp/repos/eu

# Every variable seems set, let's go!

if [[ ! -d "$repo_path/$repo_name/.git" ]] || [[ "$clean_repo" == "true" ]]  # not exist or not git repo
then
        if [[ -d "$repo_path" ]]
        then
                echo "deleting existing repo $repo_path"
                rm -rf "$repo_path" 
        fi
        echo "Attempting clone"
        mkdir -p "$repo_path"

        GIT_SSH_COMMAND="ssh -i $repo_id -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no'" git -C "$repo_path" clone --recurse-submodules --remote-submodules "$repo_url" "$repo_name" 
else
        git -C "$repo_path/$repo_name" reset --hard HEAD
        GIT_SSH_COMMAND="ssh -i $repo_id -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no'" git -C "$repo_path/$repo_name" pull
        if [[ -f "$repo_path/$repo_name/.gitmodules" ]] 
        then
                echo "Updating submodules"
                GIT_SSH_COMMAND="ssh -i $repo_id -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no'" git -C "$repo_path/$repo_name" submodule update --recursive 
        fi

fi

hugo --config "${repo_path}/${repo_name}/config.toml" --source "${repo_path}/${repo_name}" --log --logFile "$repo_base/hugo.log" --verbose --verboseLog --cleanDestinationDir --destination "${repo_path/$repo_base/$www_target}/${repo_name}"