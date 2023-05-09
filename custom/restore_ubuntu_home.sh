#!/bin/bash

set -e

setup_sudoer() {
	echo "daehnc ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/daehnc
}

restore_home_dir() {
	echo "restoring home directory..."
	rsync --ignore-existing --stats -i -r -tgo -p -l -D --password-file=$HOME/.ssh/backup.rsync backup@cloudy::Backup/$(hostname)/home/ .
}

restore_root_file() {
	source_file=$1
	dest_file="/$source_file"
	echo "restoring [$source_file] to [$dest_file]"
	sudo rsync --ignore-existing -i -r -tgo -p -l -D --password-file=/root/.ssh/backup.rsync "backup@cloudy::Backup/$(hostname)/timeshift/$source_file" "$dest_file"
}

need_install() {
	prog_name=$1
	echo -n "checking $prog_name..."
	type $prog_name >/dev/null 2>&1
	exit_code=$?
	if [ $exit_code -eq 0 ];then 
		echo "[already installed]"
		return 1
	else
		echo "[need install]"
		return 0
	fi
}

download_key_and_create_source() {
	source_file=$1
	source_url=$2
	package="$3"
	keyfile=$4
	keyurl=$5
	sudo wget -qO /tmp/$keyfile $keyurl
	sudo gpg --no-default-keyring --keyring /etc/apt/keyrings/$keyfile --import /tmp/$keyfile
	create_source $source_file $source_url "$package" $keyfile
}


retrieve_key_and_create_source() {
	source_file=$1
	source_url=$2
	package="$3"
	keyfile=$4
	keyid=$5
	sudo gpg --no-default-keyring --keyring /etc/apt/keyrings/$keyfile --keyserver hkps://keyserver.ubuntu.com --recv-keys $keyid
	create_source $source_file $source_url "$package" $keyfile
}

create_source() {
	source_file=$1
	source_url=$2
	package="$3"
	keyfile=$4
	echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/$keyfile] $source_url $package" | sudo tee /etc/apt/sources.list.d/$source_file > /dev/null
}

install_packages() {
	echo "installing packages..."
	installable_packages=()
	if need_install subl; then
		download_key_and_create_source sublime-text.list https://download.sublimetext.com/ "apt/stable/" sublimehq-pub.gpg https://download.sublimetext.com/sublimehq-pub.gpg
		installable_packages+=('sublime-text')
	fi

	if need_install dropbox; then
		retrieve_key_and_create_source dropbox.list http://linux.dropbox.com/ubuntu "disco main" dropbox.pgp 1C61A2656FB57B7E4DE0F4C1FC918B335044912E 
		installable_packages+=('dropbox')
		installable_packages+=('python3-gpg')
	fi


	if need_install code; then
		keyfile=packages.microsoft.gpg
		wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > $keyfile
		sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/$keyfile
		rm -f packages.microsoft.gpg
		create_source vscode.list https://packages.microsoft.com/repos/code "stable main" $keyfile
		installable_packages+=('code')
	fi

	if need_install teams; then
		keyfile=packages.microsoft.gpg
		wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > $keyfile
		sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/$keyfile
		rm -f packages.microsoft.gpg
		create_source msteam.list https://packages.microsoft.com/repos/ms-teams "stable main" $keyfile
		installable_packages+=('teams')
	fi

	if need_install gimp; then
		installable_packages+=('gimp')
	fi
	
	if need_install zsh; then
		installable_packages+=('zsh')
	fi

	if need_install pigz;then
		installable_packages+=('pigz')
	fi

	if need_install zoom;then
		pushd ~/dev
		if [ ! -d /home/daehnc/dev/zoom-autoupdater ];then
			git clone https://github.com/pazepaze/zoom-autoupdater.git > /dev/null
		fi
		cd zoom-autoupdater
		git pull
		sudo ~/dev/zoom-autoupdater/autoupdate-zoom.sh install
		popd
		installable_packages+=('python3-gpg')
	fi
	
	if need_install google-chrome;then
		add_key_and_create_source google-chrome.list http://dl.google.com/linux/chrome/deb/ "stable main" google-chrome.gpg https://dl-ssl.google.com/linux/linux_signing_key.pub

		installable_packages+=('google-chrome-stable')
	fi

	if [ ${#installable_packages[@]} -gt 0 ];then
		echo "installing ${installable_packages[@]}..."
		sudo apt-get update
		sudo apt-get install ${installable_packages[@]}
		if [ -f /etc/apt/sources.list.d/teams.list ];then
			sudo rm /etc/apt/sources.list.d/teams.list
		fi
		echo "done installing ${installable_packages[@]}..."
	fi
}

install_snaps() {
	if need_install pycharm-community; then
		sudo snap install pycharm-community --classic
	fi

	if need_install dbeaver-ce; then
		sudo snap install dbeaver-ce
	fi

	if need_install obsidian;then
		wget https://github.com/obsidianmd/obsidian-releases/releases/download/v0.15.9/obsidian_0.15.9_amd64.snap
		sudo snap install --dangerous obsidian_0.15.9_amd64.snap
		rm obsidian_0.15.9_amd64.snap
	fi
}

remove_unneccessary() {
	sudo apt remove libreoffice-\* rhythmbox-\* thunderbird\* xmahjongg
	sudo apt autoremove
}

enable_backup() {
	sudo apt install timeshift
	restore_root_file etc/timeshift/timeshift.json
	restore_root_file etc/cron.daily/1_backup_timeshift
	systemctl --user enable anacron.service
	systemctl --user start anacron.timer

}

setup_autofs() {
	# https://help.ubuntu.com/community/Autofs
	sudo apt install autofs
	sudo systemctl stop autofs
	# copy auto.* files
	restore_root_file etc/auto.master
	restore_root_file etc/auto.sshfs
	sudo systemctl start autofs
	if [ ! -d /home/daehnc/Documents/cda@cloudy ];then
		ln -s /mnt/sshfs/cloudy_cda /home/daehnc/Documents/cda@cloudy
	fi
}

setup_wifi() {
	# https://confluence.tdservice.cloud/display/TDDashboard/Ubuntu
	WIFI_INTERFACE=$(find /sys/class/net -follow -maxdepth 2 -name wireless 2>/dev/null | cut -d / -f 5)
	sudo nmcli connection add type wifi con-name "TechDivision" ifname $WIFI_INTERFACE ssid "TechDivision-5G" -- wifi-sec.key-mgmt wpa-eap 802-1x.eap ttls 802-1x.phase2-auth pap 802-1x.identity "$USERNAME" 802-1x.anonymous-identity "" 802-1x.ca-cert "/etc/ssl/certs/ISRG_Root_X1.pem" 802-1x.password-flags 1
}

setup_sudoer
restore_home_dir
install_packages
install_snaps
remove_unneccessary
enable_backup
setup_autofs
setup_wifi

if [ ! $SHELL = "/bin/zsh" ];then 
	sudo chsh -s /bin/zsh $(whoami)
fi
