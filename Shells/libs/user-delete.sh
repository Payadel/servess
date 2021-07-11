#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

#Get username
if [ -z $1 ]; then
    printf "Username: "
    read username
else
    username=$1
fi

homeDir=$(getent passwd "$username" | cut -d: -f6)
if [ "$?" != 0 ] || [ -z "$homeDir" ]; then
    echo -e "$ERROR_COLORIZED: Can't detect user home directory."
    printf "User home directory: "
    read homeDir

    if [ ! -d "$homeDir" ]; then
        echo -e "$ERROR_COLORIZED: Invalid directory."
        exit 1
    fi
fi
echo -e "$INFO_COLORIZED: User home directory detected: $homeDir"

#log out active sessions
user_sessions=$(pgrep -u test)
if [ ! -z "$user_sessions" ]; then
    echo ""
    printf "The user still loggin. do you want log out user? (y/n): "
    read logOut_user
    if [ "$logOut_user" -eq "y" ] || [ "$logOut_user" -eq "Y" ]; then
        sudo killall -9 -u "$username"
        exit_if_operation_failed "$?"
    else
        echo -e "$WARNING_COLORIZED: Operation canceled."
        exit 0
    fi
fi

#lock user to prevent login again
sudo passwd -l "$username"
say_warning_if_operation_failed "$?"

#Create backup from user directory
printf "do you wand create backup from user data? (y/n): "
read create_backup
if [ "$create_backup" -eq "y" ] || [ "$create_backup" -eq "Y" ]; then
    backup_dir="/var/server-backups"
    printf "Backup directory (default: $backup_dir): "
    read input

    if [ ! -z "$input" ]; then
        backup_dir="$input"
    fi

    if [ ! -d "$backup_dir" ]; then
        sudo mkdir -p "$backup_dir" && chmod 640 "$backup_dir"
        exit_if_operation_failed "$?"
    fi

    sudo tar -zcvf "$backup_dir/${username}_backup.tgz $homeDir"
    exit_if_operation_failed "$?"
fi

printf "do you wand delete user home dir? (y/n): "
read delete_user_homeDir
if [ "$delete_user_homeDir" -eq "y" ] || [ "$delete_user_homeDir" -eq "Y" ]; then
    sudo userdel -r -f "$username"
else
    sudo userdel -f "$username"
fi
exit_if_operation_failed "$?"
