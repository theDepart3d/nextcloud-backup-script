
# Nextcloud Backup Script
Simple Way to create backups for Nextcloud. Ability to backup both the nextcloud directory and database automatically using cronjob.
Tired of manually creating backups. This is a simple answer, the script can be runned manually or automatically.

Backups are all stored by day and time, incase multiple backups are created in a day.
- ~/nextcloud_backups/YYYY-M-D/HTM
- ~/nextcloud_backups/2024-01-01/12T47

## Requirements
All requirements will be installed automatically if not found
- PV
- mysqldump
- zip
- OS: Ubuntu/Debian

## Installation

First you will need root access to the server. EUID 0 (/root/)
Clone the script into your /root/ directory (~/ == /root/)

```bash
  git clone https://github.com/theDepart3d/nextcloud-backup-script.git
  cd nextcloud-backup-script
  chmod +x backup-nextcloud.sh
```

## Manual USAGE

```bash
# to run the script manually all you need to do is.
./backup-nextcloud.sh
# or 
bash backup-nextcloud.sh
```

## Automation USAGE

```bash
# ./backup-nextcloud.sh <NC_DIR> <BACKUP_DIR_LOCATION>
# Example USAGE for nextcloud install location /var/www/html
# backup dir will be stored in /root/ to avoid unwanted access
./backup-nextcloud.sh /var/www/html /root/nextcloud_backups
```

The above will automate the html directory zip as well as the database backup.

## Crontab USAGE
Bellow cronjob will backup the directory as well as the database every 7 days
```bash
* * 7 * * cd ~/nextcloud-backup-script && /bin/bash backup-nextcloud.sh /var/www/html /root/nextcloud_backups > /dev/null 2>&1
```
## LICENSE
[![GPLv3 License](https://img.shields.io/badge/License-GPL%20v3-yellow.svg)](https://opensource.org/licenses/) 

![Build Passing](https://img.shields.io/badge/build-passing-brightgreen.svg)