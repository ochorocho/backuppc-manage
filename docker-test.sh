#!/bin/bash

apt update && export DEBIAN_FRONTEND=noninteractive && export TZ=Europe/Berlin && apt -y install sudo tzdata make
chmod +x /tmp/*
sudo /tmp/backuppc-manage.sh --install --confirm --backuppc-version 4.4.0 --rsync-bpc-version 3.1.3.0
sudo /tmp/test.sh
