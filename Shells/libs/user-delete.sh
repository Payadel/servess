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

#Check is user exist?
id "$username" &>/dev/null
if [ "$?" != "0" ]; then
    echo -e "$ERROR_COLORIZED: The user does not exist." >&2
    exit 1
fi

#Find user home dir
homeDir=$(getent passwd "$username" | cut -d: -f6)
if [ "$?" != 0 ] || [ -z "$homeDir" ]; then
    echo -e "$ERROR_COLORIZED: Can't detect user home directory."
    printf "User home directory: "
    read homeDir

    if [ ! -d "$homeDir" ]; then
        echo -e "$ERROR_COLORIZED: Invalid directory."
        exit 1
    fi
else
    echo -e "$INFO_COLORIZED: User home directory detected: $homeDir"
fi

ls -dlh "$homeDir"
echo -e "$WARNING_COLORIZED!"
printf "Are you sure? (y/n): "
read confirm_user_dir
if [ "$confirm_user_dir" != "y" ] && [ "$confirm_user_dir" != "Y" ]; then
    echo -e "$INFO_COLORIZED: Operation canceled."
    exit 0
fi
#============================================================================

#log out active sessions
user_sessions=$(pgrep -u $username)
if [ ! -z "$user_sessions" ]; then
    echo ""
    printf "The user still login. do you want log out user? (y/n): "
    read logOut_user
    if [ "$logOut_user" = "y" ] || [ "$logOut_user" = "Y" ]; then
        sudo killall -9 -u "$username"
        exit_if_operation_failed "$?"
    else
        echo -e "$WARNING_COLORIZED: Operation canceled."
        exit 0
    fi
fi

#lock user to prevent login again
sudo passwd -l "$username"
show_warning_if_operation_failed "$?"

#Create backup from user directory
printf "do you wand create backup from user data? (y/n): "
read create_backup
if [ "$create_backup" = "y" ] || [ "$create_backup" = "Y" ]; then
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

    sudo tar -zcvf "$backup_dir/user_${username}_backup.tgz" "$homeDir"
    exit_if_operation_failed "$?"
fi

printf "do you wand delete user home dir? (y/n): "
read delete_user_homeDir
if [ "$delete_user_homeDir" = "y" ] || [ "$delete_user_homeDir" = "Y" ]; then
    temp=$(sudo chattr -R -i "$homeDir" 2>/dev/null)
    sudo userdel -r -f "$username"
else
    sudo userdel -f "$username"
fi
exit_if_operation_failed "$?"

#Access ssh
allowUsers=$(servess sshd ssh-access -la | gawk -F ': ' '{ print $2 }')
echo "Config ssh access..."
if [ ! -z "$allowUsers" ]; then
    is_exist=$(servess sshd ssh-access -la | grep -E "(^| )${username}( |$)")
    if [ ! -z "$is_exist" ]; then
        echo "Removing user from allow ssh access list..."
        servess sshd ssh-access -ra "$username" -la
    fi
fi

denyUsers=$(servess sshd ssh-access -ld | gawk -F ': ' '{ print $2 }')
if [ ! -z "$denyUsers" ]; then
    is_exist=$(servess sshd ssh-access -ld | grep -E "(^| )${username}( |$)")
    if [ ! -z "$is_exist" ]; then
        echo "Removing user from deny ssh access list..."
        servess sshd ssh-access -rd "$username" -ld
    fi
fi
show_warning_if_operation_failed "$?"

echo "Restarting ssh..."
sudo systemctl restart ssh
show_warning_if_operation_failed "$?"
#=======================================================================

echo -e "$DONE_COLORIZED"
