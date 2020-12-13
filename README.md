# Install/update/remove BackupPC with ease

Tested on Ubuntu 20.04. Should work on any Debian like OS

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
