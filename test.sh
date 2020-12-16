#!/bin/bash

echo "Check if all binaries are available ..."
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
which sendmail || echo "Sendmail is optional"
which smbclient || exit 1
which split || exit 1
which ssh || exit 1

echo "Check cleanup ..."

[ -f "BackupPC.tar.gz" ] && exit "Archive still exists"
[ -f "rsync-bpc.tar.gz" ] && exit "Archive still exists"
[ -d $(echo BackupPC-*) ] && exit "Folder still exists"
[ -d $(echo rsync-bpc-*) ] && exit "Folder still exists"

sudo systemctl is-active --quiet backuppc.service && echo "BackupPC is running ... well done!"

echo "Tests done ... Good Luck"

