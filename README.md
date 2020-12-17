# Install/update/remove BackupPC with ease

Tested on Ubuntu 20.04 and CentOS 8. Should work on any Debian like OS.

Stick to BackupPC's installer defaults if possible.

## Commands

Install BackupPC latest version hosted on GitHub:

```bash
./backuppc-manage.sh --install
```

Uninstall BackupPC

```bash
./backuppc-manage.sh --remove
```

Install specific version of [BackupPC](https://github.com/backuppc/backuppc/releases) and [rsync-bpc](https://github.com/backuppc/rsync-bpc/releases)

```bash
./backuppc-manage.sh --install --backuppc-version=4.4.0 --rsync-bpc-version=3.1.3.0
```

# Configure Webserver

## Apache2 config

Install mod_scgi package Ubuntu/Debian using `apt`
```
apt install libapache2-mod-scgi
```

or download and install manually

```
curl -L -o libapache2-mod-scgi.deb http://mirrors.kernel.org/ubuntu/pool/universe/s/scgi/libapache2-mod-scgi_1.13-1.1build1_amd64.deb
sudo dpkg -i libapache2-mod-scgi.deb
```

Create `/etc/apache2/sites-enabled/backuppc.conf` with the following content:

```
LoadModule scgi_module modules/mod_scgi.so
SCGIMount /BackupPC_Admin 127.0.0.1:10268
<Location /BackupPC_Admin>
    AuthUserFile /etc/BackupPC/passwd
    AuthType basic
    AuthName "access"
    require valid-user
</Location>
Alias           /BackupPC         /var/www/BackupPC/
```
	
Run `a2ensite backuppc` to enable apache config and `htpasswd -c /etc/BackupPC/passwd <USERNAME>` to create a user"

## Local testing

Ubuntu

```
docker run --rm -it -w /backuppc_install/ -v `pwd`/:/backuppc_install/ --entrypoint "bash" ubuntu:20.04 /backuppc_install/test.sh
```

CentOS

```
docker run --rm -it -w /backuppc_install/ -v `pwd`/:/backuppc_install/ --entrypoint "bash" centos:8 /backuppc_install/test.sh
```
