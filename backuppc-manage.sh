#!/bin/bash

# TEST WITH CENTOS

get_latest_release () {
	curl --silent "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

output () {
   echo -e "\n\033[1m$1\033[0m\n"
}

get_config () {
	if sudo test -f "/etc/BackupPC/config.pl"; then
		sudo grep "\$Conf{$1}" /etc/BackupPC/config.pl | grep -o -P "(?<=').*(?=')"
	fi
}

get_packagemanager () {
	declare -A osInfo;
	osInfo[/etc/redhat-release]="yum"
	osInfo[/etc/debian_version]="apt"

	for f in "${!osInfo[@]}"
	do
	    if [[ -f $f ]];then
	        echo "${osInfo[$f]}"
	    fi
	done
}

PM=$(get_packagemanager)
ASSETS=/var/www/BackupPC/
HOME=/var/lib/backuppc

# Parse arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

	case $key in
	    -bpcv|--backuppc-version)
	    BACKUPPC_VERSION="$2"
	    shift
	    shift
	    ;;
	    -rbcpv|--rsync-bpc-version)
	    RSYNC_BPC="$2"
	    shift
	    shift
	    ;;
	    --install)
	    INSTALL="YES"
	    shift
	    ;;
	    --remove)
	    REMOVE="YES"
	    shift
	    ;;
	    --confirm)
	    CONFIRM="-y"
	    shift
	    ;;
	    *)    # unknown option
	    POSITIONAL+=("$1")
	    shift
	    ;;
	esac
done
set -- "${POSITIONAL[@]}"

# Break if no action given
if [ -z "$INSTALL" ] && [ -z "$REMOVE" ]; then
    echo "Choose a action you want to use. Either '--install' or '--remove'"
	exit 1
fi

# Set latest version if none defined
if [ -z "$BACKUPPC_VERSION" ]; then
  BACKUPPC_VERSION=$(get_latest_release "backuppc/backuppc")
fi

if [ -z "$RSYNC_BPC" ]; then
  RSYNC_BPC=$(get_latest_release "backuppc/rsync-bpc")
fi

install_rsync_bpc () {
	output "Install rsync-bpc version $RSYNC_BPC ..."
	curl -L -o rsync-bpc.tar.gz "https://github.com/backuppc/rsync-bpc/releases/download/$RSYNC_BPC/rsync-bpc-$RSYNC_BPC.tar.gz"
	tar zxf rsync-bpc.tar.gz
	cd "rsync-bpc-$RSYNC_BPC" || exit
	./configure
	make
	sudo make install
	cd ..
}

install_perl_modules () {
	output "Install perl modules ..."

	sudo PERL_MM_USE_DEFAULT=1 cpanm Archive::Zip \
		XML::RSS  \
		JSON::XS  \
		CGI  \
		SCGI \
		File::Listing \
		BackupPC::XS \
 		Net::FTP \
		Test::Differences
# 		Net::FTP::RetrHandle \
# 		Net::FTP::AutoReconnect \
}

install_backuppc () {
	output "Install BackupPC version $BACKUPPC_VERSION ..."
	curl -L -o BackupPC.tar.gz "https://github.com/backuppc/backuppc/releases/download/$BACKUPPC_VERSION/BackupPC-$BACKUPPC_VERSION.tar.gz"
	tar zxf BackupPC.tar.gz
	cd "BackupPC-$BACKUPPC_VERSION" || exit
	sudo perl configure.pl --batch \
		--hostname hostname \
		--data-dir /data/backuppc \
		--html-dir $ASSETS \
		--html-dir-url /BackupPC \
		--scgi-port 10268 \
		--install-dir /usr/local/BackupPC \
		--backuppc-user backuppc \
		--config-override CgiAdminUsers=\"backuppc\"
	cd ..
}

systemctl_configure () {
	output "Add systemd service file ..."
	yes | sudo cp -f BackupPC-"$BACKUPPC_VERSION"/systemd/backuppc.service /etc/systemd/system/backuppc.service
	sudo systemctl daemon-reload
}

copy_assets () {
	output "Copy assets to $ASSETS"
	sudo mkdir -p $ASSETS
	sudo cp -f BackupPC-"$BACKUPPC_VERSION"/conf/BackupPC_* $ASSETS
	sudo cp -f BackupPC-"$BACKUPPC_VERSION"/images/* $ASSETS
}

remove_file() {
	[ -f "$1" ] && sudo rm -f "$1"
}

remove_folder() {
	[ -d "$1" ] && sudo rm -rf "$1"
}

cleanup () {
	output "Cleanup files ..."
	remove_file "rsync-bpc.tar.gz"
	remove_file "BackupPC.tar.gz"
	remove_folder "BackupPC-$BACKUPPC_VERSION"
	remove_folder "rsync-bpc-$RSYNC_BPC"
}

remove_folder_confirm () {
	if [ "$1" = "" ]; then
		output "Could not delete folder due to not existing/empty config value"
	else
		read -p "Really want to delete $1? [y/n] " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Yy]$ ]]
		then
			remove_folder "$1"
		fi
	fi
}

create_user () {
	if id "$1" &>/dev/null; then
	    output "User 'backuppc' already exists ..."
	else
	    output "Creating '$1' user ..."
		if [ "$PM" = "apt" ]; then
			sudo -i addgroup --system "$1"
			sudo -i adduser --system --gecos "BackupPC" --ingroup "$1" --shell /bin/sh --home "$HOME" "$1"
		fi

		if [ "$PM" = "yum" ]; then
			sudo -i groupadd --system "$1"
			sudo -i useradd --system -g "$1" --shell /bin/sh --home-dir "$HOME" "$1"
		fi

		if [ "$PM" = "" ]; then
			output "Could not create user"
			exit 1
		fi
	fi
}

if [ "$REMOVE" = "YES" ]; then
	sudo systemctl is-active --quiet backuppc.service && sudo systemctl stop backuppc.service
	remove_file "/etc/systemd/system/backuppc.service"
	sudo systemctl daemon-reload

	TOP_DIR=$(get_config 'TopDir')
	CONF_DIR=$(get_config 'ConfDir')
	LOG_DIR=$(get_config 'LogDir')
	RUN_DIR=$(get_config 'RunDir')
	INSTALL_DIR=$(get_config 'InstallDir')

	remove_folder_confirm "$INSTALL_DIR"
	remove_folder_confirm "$LOG_DIR"
	remove_folder_confirm "$RUN_DIR"
	remove_folder_confirm "$CONF_DIR"
	remove_folder "$ASSETS/*"
	remove_folder "$HOME"


	output "BackupPC removed ... Data directory $TOP_DIR was not deleted."
fi

if [ "$INSTALL" = "YES" ]; then
	output "Install required *.deb packages ..."

	if [ "$PM" = "" ]; then
		output "Could not determine Package Manager"
		exit 1
	fi

	if [ "$PM" = "apt" ]; then
		sudo "$PM" $CONFIRM install systemctl make gcc libacl1-dev apache2-utils curl perl smbclient rrdtool rsync par2 tar cpanminus iputils-ping
	fi

	if [ "$PM" = "yum" ]; then
		sudo "$PM" -y install epel-release
		sudo "$PM" $CONFIRM install systemctl make gcc libacl-devel httpd-tools curl perl samba-client rrdtool rsync par2cmdline tar cpanminus iputils
	fi

 	install_perl_modules
	install_rsync_bpc
	create_user "backuppc"
	install_backuppc

	systemctl_configure
	copy_assets
	#cleanup

	htpasswd -b -c /etc/BackupPC/passwd backuppc backuppc
	sudo systemctl start backuppc.service
	sudo systemctl is-active --quiet backuppc.service && output "BackupPC started and running..."

	output "Installation finished..."
	echo "Configure your webserver as you wish. Apache example: https://github.com/ochorocho/backuppc-manage/#configure-webserver"
fi
