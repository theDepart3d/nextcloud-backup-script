#!/bin/bash
# Made By The Departed
# clear terminal
clear
# Show Welcome
VERSION='1.1.3'
echo "============================================="
echo "|              Nextcloud Backup             |"
echo "|                   Script                  |"
echo "|                   v${VERSION}                  |"
echo "============================================="
echo ""

# Script Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
ORANGE='\033[1;33m'
NC='\033[0m' # No Color

NC_DIRECTORY=$1
NC_BACKUP_FOLDER=$2
PKG_REQUIREMENTS=("mysqldump" "zip" "rsync" "pv" "gzip")

# Abilit to add color to certain outputs
echoc () {
    echo -e $1;
}

# check os before running script
case "$OSTYPE" in
    darwin*)  
        echo -e "${RED}MacOS is not supported by default${NC}"
        exit
    ;; 
    msys*)  
        echo -e "${RED}Windows is not supported by default${NC}"
        exit
    ;;
    cygwin*)  
        echo -e "${RED}Windows is not supported by default${NC}"
        exit
    ;;
esac

# Must be root to run this script
if (( $EUID != 0 )); then
    echoc ${RED}"Please run as root "${NC}
    exit
fi

# Check if required pkgs are installed for script
echoc ${ORANGE}'Status'${NC}": Checking if required packages are installed"
for required_pkg in "${PKG_REQUIREMENTS[@]}"
do
    if ! command -v $required_pkg &> /dev/null; then
        echoc ${GREEN}'Status'${NC}": Installing $required_pkg"
        apt-get install $required_pkg -y &> /dev/null
    fi
done
echoc ${GREEN}'Status'${NC}": Required packages installed"

# Check if Backup Directory set
if test -z "$NC_BACKUP_FOLDER"; then
    read -p 'Backup Folder Location: ' NC_BACKUP_FOLDER;
fi

echo -e ${GREEN}'Status'${NC}": Entered $NC_BACKUP_FOLDER"

if [ -d $NC_BACKUP_FOLDER/$(date +'%Y-%m-%d')/ ]; then
    cd $NC_BACKUP_FOLDER/$(date +'%Y-%m-%d')/
    echo -e ${GREEN}'Status'${NC}": Entered $NC_BACKUP_FOLDER/"$(date +'%Y-%m-%d')
else
    mkdir -p $NC_BACKUP_FOLDER/$(date +'%Y-%m-%d')/$(date +'%HT%M')
    cd $NC_BACKUP_FOLDER/$(date +'%Y-%m-%d')/$(date +'%HT%M')
fi

create_folder () {
    cd $NC_BACKUP_FOLDER/$(date +'%Y-%m-%d')/$(date +'%HT%M')
    echoc ${GREEN}'Status'${NC}": Entered $NC_BACKUP_FOLDER/"$(date +'%F')/$(date +'%HT%M')
    echoc ${ORANGE}'Status'${NC}
    if test -z "$NC_DIRECTORY"; then
        read -p 'Enter valid nextcloud directory: ' NC_DIRECTORY;
    fi
    if [ -d $NC_DIRECTORY ]; then
        # Enable Maintenance Mode 
        sudo -u www-data php $NC_DIRECTORY/occ maintenance:mode --on
        echoc ${GREEN}'Status'${NC}': '$NC_DIRECTORY' valid directory'
        echoc ${GREEN}'Status'${NC}': Creating zip'
        zip -r wwwDirBackup-$(date +'%Y-%m-%d').zip $NC_DIRECTORY 2>&1 | pv -lep -s $(ls -Rl1 $NC_DIRECTORY | egrep -c '^[-/]') > /dev/null
        echoc ${GREEN}'Status'${NC}': Zip file created' 
        echo ""
        echo "============================================="
        echo -e ${GREEN}
        echo "      Status: Directory Backup Complete"
        echo -e ${NC}
        echo "============================================="
        echo ""
    else
        echoc ${RED}'Status'${NC}': Input is not a valid folder'
	    rm -r ../$(date +'%HT%M')
        exit;
    fi
    echoc ${GREEN}'Status'${NC}': Dumping SQL'
    NC_CONFIG_FILE="$NC_DIRECTORY/config/config.php"
    if [ ! -e "$NC_CONFIG_FILE" ]; then
        read -p "Enter Database HOST: " DBHOST
        read -p "Enter Database Port: " DBPORT
        read -p "Enter Database User: " DBUSER
        read -p "Enter Database Name: " DBNAME
        mysqldump -h $DBHOST -P $DBPORT -p -u $DBUSER --databases $DBNAME > $DBNAME.sql 2> database_backup.log
        if [ "$?" -eq 0 ]; then
            gzip $DBNAME.sql
            echo ""
            echo "============================================="
            echo -e ${GREEN}
            echo "           Status: Backup Complete"
            echo -e ${NC}
            echo "============================================="
            echo ""
            rm -r database_backup.log
            # Disable Maintenance Mode 
            sudo -u www-data php $NC_DIRECTORY/occ maintenance:mode --off
        else
            echo ""
            echo "============================================="
            echo -e ${RED}
            echo "       Status: Database Backup Failed"
            echo -e ${NC}
            echo "============================================="
            echo ""
            echo -e "mysqldump encountered a problem look in ${RED}$NC_WORKING_FOLDER/database_backup.log${NC} for more information."
        fi
    else
        DBNAME=$(grep -Po "(?<='dbname' => ').*(?=',)" $NC_CONFIG_FILE) 
        DBHOST=$(grep -Po "(?<='dbhost' => ').*(?=',)" $NC_CONFIG_FILE) 
        DBPORT=$(grep -Po "(?<='dbport' => ').*(?=',)" $NC_CONFIG_FILE) 
        DBPASSWD=$(grep -Po "(?<='dbpassword' => ').*(?=',)" $NC_CONFIG_FILE) 
        DBUSER=$(grep -Po "(?<='dbuser' => ').*(?=',)" $NC_CONFIG_FILE) 
        if test -z "$DBPORT"; then
            DBPORT='3306'
        fi
        mysqldump -h $DBHOST -P $DBPORT --password="$DBPASSWD" -u $DBUSER --databases $DBNAME > $DBNAME.sql 2> database_backup.log
        if [ "$?" -eq 0 ]; then
            gzip $DBNAME.sql
            echo ""
            echo "============================================="
            echo -e ${GREEN}
            echo "           Status: Backup Complete"
            echo -e ${NC}
            echo "============================================="
            echo ""
            echoc -e ${GREEN} "Backup Folder"${NC}": $NC_WORKING_FOLDER"
            rm -r database_backup.log
            # Disable Maintenance Mode 
            sudo -u www-data php $NC_DIRECTORY/occ maintenance:mode --off
        else
            echo ""
            echo "============================================="
            echo -e ${RED}
            echo "       Status: Database Backup Failed"
            echo -e ${NC}
            echo "============================================="
            echo ""
            echo -e "mysqldump encountered a problem look in ${RED}$NC_WORKING_FOLDER/database_backup.log${NC} for more information."
        fi
    fi
}

if [ -d $NC_BACKUP_FOLDER/$(date +'%F')/$(date +'%HT%M')/ ]; then
    NC_WORKING_FOLDER="$NC_BACKUP_FOLDER/$(date +'%Y-%m-%d')/$(date +'%HT%M')"
    create_folder
else
    NC_WORKING_FOLDER="$NC_BACKUP_FOLDER/$(date +'%Y-%m-%d')/$(date +'%HT%M')"
    echoc ${GREEN}'Status'${NC}": Creating New folder: $NC_BACKUP_FOLDER/$(date +'%F')/$(date +'%HT%M')"
    mkdir $(date +'%HT%M')
    create_folder
fi