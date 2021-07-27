#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/sshKey-config.sh ] || [ ! -f /opt/shell-libs/user-delete.sh ] || [ ! -f /opt/shell-libs/user-ssh-access.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1

fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

delete_user_if_operation_failed() {
    local code="$1"

    if [ "$code" != "0" ]; then
        echo -e "$ERROR_COLORIZED: Operation failed."
        printf "Do you want delete user? (y/n): "
        read delete_user

        if [ "$delete_user" = "y" ] || [ "$delete_user" = "Y" ]; then
            /opt/shell-libs/user-delete.sh "$delete_user"
        fi
    fi
}

if [ -z $1 ]; then
    printf "Username: "
    read username
else
    username=$1
fi

sudo_group="$2"
root_group="$3"
disable_banner="$4"
expire_password="$5"
allow_ssh="$6"
add_ssh_key="$7"
#========================================================================

is_user_exist=$(id "$username" 2>/dev/null)
if [ "$?" = "0" ]; then
    echo -e "$ERROR_COLORIZED: The user already exists." >&2
    exit 1
fi

#Home directory
home_dir="/home/$username"
printf "Input user home directory (default: $home_dir): "
read input_home_dir
if [ ! -z "$input_home_dir" ]; then
    home_dir="$input_home_dir"
fi

if [ -d "$home_dir" ]; then
    printf "Directory $home_dir already exists. do you want delete it? (y/n): "
    read delete_home_dir
    if [ "$delete_home_dir" = "y" ] || [ "$delete_home_dir" = "Y" ]; then
        chattr -R -i "$home_dir" && sudo rm -r "$home_dir"
        exit_if_operation_failed "$?"
    fi
fi

sudo adduser --home "$home_dir" "$username"
exit_if_operation_failed "$?"

if [ ! -d "$home_dir" ]; then
    sudo mkdir -p "$home_dir"
fi
sudo chown "$username:$username" "$home_dir" && chmod 750 "$home_dir"
delete_user_if_operation_failed "$?"

#Sudo group?
if [ -z "$sudo_group" ]; then
    printf "Add user to sudo group? (y/n): "
    read sudo_group
fi
if [ "$sudo_group" = "y" ] || [ "$sudo_group" = "Y" ]; then
    sudo usermod -aG sudo "$username"
    delete_user_if_operation_failed "$?"
fi

#root group?
if [ -z "$root_group" ]; then
    printf "Add user to root group? (y/n): "
    read root_group
fi
if [ "$root_group" = "y" ] || [ "$root_group" = "Y" ]; then
    sudo usermod -aG root "$username"
    delete_user_if_operation_failed "$?"
fi

#Disables welcome banner
if [ -z "$disable_banner" ]; then
    printf "Disables welcome banner? (y/n): "
    read disable_banner
fi
if [ "$disable_banner" = "y" ] || [ "$disable_banner" = "Y" ]; then
    sudo touch "$home_dir/.hushlogin" && chattr +i "$home_dir/.hushlogin"
    delete_user_if_operation_failed "$?"
fi

#Disables welcome banner
if [ -z "$expire_password" ]; then
    printf "force expire the password (the user must change password after login)? (y/n): "
    read expire_password
fi
if [ "$expire_password" = "y" ] || [ "$expire_password" = "Y" ]; then
    sudo passwd -e "$username"
    show_warning_if_operation_failed "$?"
fi

#Access ssh
/opt/shell-libs/user-ssh-access.sh "$username" "$allow_ssh"
delete_user_if_operation_failed "$?"
echo ""

#SSH Key
if [ -z "$add_ssh_key" ]; then
    printf "Do you want add ssh key? (y/n): "
    read add_ssh_key
fi
if [ "$add_ssh_key" = "y" ] || [ "$add_ssh_key" = "Y" ]; then
    /opt/shell-libs/sshKey-config.sh "$username"
    delete_user_if_operation_failed "$?"
fi

echo_info "Restarting ssh..."
sudo systemctl restart ssh
show_warning_if_operation_failed "$?"
#=====================================================================
