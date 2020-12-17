#!/bin/bash

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

[ "$PM" = "yum" ] && grep -i centos < /etc/redhat-release && $PM install -y epel-release which
$PM update -y && export DEBIAN_FRONTEND=noninteractive && export TZ=Europe/Berlin && $PM install -y sudo tzdata make
[ "$PM" = "yum" ] && grep -i centos < /etc/redhat-release && sudo "$PM" remove -y epel-release

# Install BackupPC
./backuppc-manage.sh --install --confirm --backuppc-version 4.4.0 --rsync-bpc-version 3.1.3.0

# Do some testing
echo "Check if all required binaries are available ..."
which bzip2 || exit 1
which cat || exit 1
which df || exit 1
which tar || exit 1
which gzip || exit 1
which hostname || exit 1
which nmblookup || exit 1
which par2 || exit 1
which perl || exit 1
which ping || exit 1
which ping6 || exit 1
which rrdtool || exit 1
which rsync || exit 1
which rsync_bpc || exit 1
which sendmail || echo "Sendmail is not installed (optional)"
which smbclient || exit 1
which split || exit 1
which ssh || exit 1

echo "Check cleanup ..."

[ -f "BackupPC.tar.gz" ] && echo "Archive still exists" && exit 1
[ -f "rsync-bpc.tar.gz" ] && echo "Archive still exists" && exit 1
[ -d "$(echo BackupPC-*)" ] && echo "Folder still exists" && exit 1
[ -d "$(echo rsync-bpc-*)" ] && echo "Folder still exists" && exit 1

sudo service backuppc status | grep running && echo "BackupPC is running ... well done!" || exit 1

echo "Tests done ... Good Luck"

