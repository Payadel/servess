run() {
    process_name=$1
    execute_path=$2

    printf "Processing $process_name...\n"
    echo "Processing $process_name..." >>$statusFile

    sudo chmod +x $execute_path
    $execute_path $3 $4 $5 $6 $7 $8 $9

    if [ $? -eq 0 ]; then
        echo "DONE."
        echo "DONE." >>$statusFile
    else
        echo "FAILED."
        echo "FAILED." >>$statusFile
        # notify-send "$process_name" 'An error has occurred.' -u critical
        exit
    fi

    echo "============================================================" >>$statusFile
    echo "============================================================"
    echo "============================================================"
    echo "============================================================"
}

#Inputs:
if [ -z "$1" ]; then
    printf "Input backup path (default: /var): "
    read backup_basePath
    if [ -z "$backup_basePath" ]; then
        backup_basePath="/var"
    fi
else
    backup_basePath=$1
fi
backup_dirName="server-backups"
backup_dir="$backup_basePath/$backup_dirName"
sudo mkdir -p "$backup_dir"
sudo chmod 750 "$backup_dir"
chattr +i "$backup_dir"

# Status file
statusFile="install-status.txt"
if [ -f "$statusFile" ]; then
    rm "$statusFile"
fi
touch "$statusFile"
sudo chmod 750 "$statusFile"

#Server finger print
run "Server Finger Print" /opt/shell-libs/serverFingerPrint-get.sh

#timeshift
run "install timeshift" /opt/shell-libs/timeshift-install.sh
run "Create Timeshift Backup" /opt/shell-libs/timeshift-createBackup.sh "First Backup"
chmod 750 /timeshift
chattr +i /timeshift

#Update
run "update" /opt/shell-libs/update.sh

#Git:
#run "Git" /opt/shell-libs/git-install.sh

#=======================================================================
#Use editor
editor="nano"

#Dns:
backup_name=$(date +"%s")
run "Backup dns" /opt/shell-libs/backup.sh "/etc/netplan/01-netcfg.yaml" "$backup_dir/etc/netplan" "$backup_name-before"
run "Dns" /opt/shell-libs/dns-change.sh "$editor"
run "Backup dns" /opt/shell-libs/backup.sh "/etc/netplan/01-netcfg.yaml" "$backup_dir/etc/netplan" "$backup_name-updated"

#Update
run "Update" /opt/shell-libs/update.sh

#SSH-Key
run "SSH Key config" /opt/shell-libs/sshKey-config.sh "$editor"

#Disable password
name=$(date +"%s")
run "Backup sshd_config" /opt/shell-libs/backup.sh "/etc/ssh/sshd_config" "$backup_dir/etc/ssh/sshd_config" "$name-before"
run "Disable login with password" /opt/shell-libs/password-disable.sh
run "Backup sshd_config" /opt/shell-libs/backup.sh "/etc/ssh/sshd_config" "$backup_dir/etc/ssh/sshd_config" "$name-updated"

#curl
run "install curl" /opt/shell-libs/curl-install.sh

#node, npm
#run "install node" /opt/shell-libs/node-install.sh

#nestjs
#run "install nestjs" /opt/shell-libs/nestjs-install.sh

#pm2
#run "install pm2" /opt/shell-libs/pm2-install.sh

#nginx
run "install nginx" /opt/shell-libs/nginx-install.sh
backup_name=$(date +"%s")
run "Backup nginx config" /opt/shell-libs/backup.sh "/etc/nginx" "$backup_dir/etc/nginx" "$name"

#mongodb
#run "install mongodb" /opt/shell-libs/mongodb-install.sh

#certbot
#run "install Free SSL" /opt/shell-libs/certbot.sh

#docker
run "install docker" /opt/shell-libs/docker-install.sh
run "install docker compose" /opt/shell-libs/docker-compose-install.sh

#Gitlab
# run "install Gitlab with docker compose" /opt/shell-libs/gitlab-install-dockerCompose.sh $editor
# run "install Gitlab" /opt/shell-libs/gitlab-install.sh $editor

#Backup
run "Create Timeshift Backup" /opt/shell-libs/timeshift-createBackup.sh "Base apps is installed"
