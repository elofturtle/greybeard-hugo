#!/usr/bin/env bash
# webhook -urlprefix postreceive  -hooks hooks.json -verbose

#!/usr/bin/env bash
bas="$(dirname $(readlink -f $0))"
source "${bas}/redeploy.conf"
clean_repo="false"

while (($#))
do
        case $1 in
                '--config')
                        shift
                        konf="$(readlink -f $1)"
                        ;;
		'--all')
			for r in $($0 --repo-list)
			do
				$0 --clean --repo $r
			done
			exit 0
			;;
                '--clean')
                        clean_repo="true"
                        ;;
                '--repo')
                        shift
                        repo="$1"
                        ;;
                '--repo-list')
                        find "$repo_dir" -type f -name '*.repo' -exec basename {} .repo \;
                        exit 0
                        ;;
                '--help'|*)
                        echo "$(basename $0):"
			            echo "  --all           reinit all repos"
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

repo_path="$repo_base/$(tr '.' $'\n' <<< "$repo" | tac | paste -s -d '/')/${repo}"  # /tmp/repos/eu/feks/feks.eu
repo_name="$(basename $repo_path)"                                                  # feks.eu
repo_path="$(dirname $repo_path)"                                                   # /tmp/repos/eu/feks
repo_id="${ssh_key_dir}/${repo_name}_id"

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

hugo --config "${repo_path}/${repo_name}/config.toml" --source "${repo_path}/${repo_name}" --log --logFile "$repo_base/hugo.log" --verbose --verboseLog --cleanDestinationDir --destination "${repo_path}/${repo_name}"
