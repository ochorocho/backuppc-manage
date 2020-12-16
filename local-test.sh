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

if [ "$PM" = "yum" ]; then
  $PM install -y epel-release
fi

$PM update -y && export DEBIAN_FRONTEND=noninteractive && export TZ=Europe/Berlin && $PM install -y sudo tzdata make which
chmod +x /tmp/*
sudo /backuppc_install/backuppc-manage.sh --install --confirm --backuppc-version 4.4.0 --rsync-bpc-version 3.1.3.0

if [ "$PM" = "yum" ]; then
  sudo "$PM" remove -y epel-release
fi

sudo "/backuppc_install/test.sh"
