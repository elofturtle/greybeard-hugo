function install_git {
	sudo dnf -y install git
}

function install_caddy {
	sudo dnf -y install 'dnf-command(copr)'
	sudo dnf copr enable @caddy/caddy
	sudo dnf -y install caddy
}
