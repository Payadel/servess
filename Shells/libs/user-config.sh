if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-ssh-access.sh ] || [ ! -f /opt/shell-libs/password-disable.sh ] || [ ! -f /opt/shell-libs/ssh-restart.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

username="$1"
sudo_group="$2"
root_group="$3"
disable_banner="$4"
expire_password="$5"
allow_ssh="$6"
add_ssh_key="$7"
disable_password="$8"

#User Name
if [ -z "$username" ]; then
    printf "Username: "
    read -r username
fi
user_must_exist "$username"

#Find user home dir
home_dir=$(/opt/shell-libs/user-get-homeDir.sh "$username")
if [ "$?" != 0 ] || [ -z "$home_dir" ]; then
    echo_error "Can't detect user home directory."
    printf "User home directory: "
    read -r home_dir

    if [ ! -d "$home_dir" ]; then
        echo_error "Invalid directory."
        exit 1
    fi
else
    echo_info "User home directory detected: $home_dir"
fi

#Sudo group?
if [ -z "$sudo_group" ]; then
    printf "Add user to sudo group? (y/n): "
    read -r sudo_group
fi
if [ "$sudo_group" = "y" ] || [ "$sudo_group" = "Y" ]; then
    sudo usermod -aG sudo "$username"
    delete_user_if_operation_failed "$?"
fi

#root group?
if [ -z "$root_group" ]; then
    printf "Add user to root group? (y/n): "
    read -r root_group
fi
if [ "$root_group" = "y" ] || [ "$root_group" = "Y" ]; then
    sudo usermod -aG root "$username"
    delete_user_if_operation_failed "$?"
fi

#Disables welcome banner
if [ -z "$disable_banner" ]; then
    printf "Disables welcome banner? (y/n): "
    read -r disable_banner
fi
if [ "$disable_banner" = "y" ] || [ "$disable_banner" = "Y" ]; then
    if [ !-f "$home_dir/.hushlogin" ]; then
        sudo touch "$home_dir/.hushlogin" && chattr +i "$home_dir/.hushlogin"
        delete_user_if_operation_failed "$?"
    fi
fi

#Expire Password after login
if [ -z "$expire_password" ]; then
    printf "force expire the password (the user must change password after login)? (y/n): "
    read -r expire_password
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
    read -r add_ssh_key
fi
if [ "$add_ssh_key" = "y" ] || [ "$add_ssh_key" = "Y" ]; then
    /opt/shell-libs/sshKey-config.sh "$username"
    delete_user_if_operation_failed "$?"
fi

/opt/shell-libs/password-disable.sh "$username" "$disable_password"
show_warning_if_operation_failed "$?"

echo_info "Restarting ssh..."
/opt/shell-libs/ssh-restart.sh
show_warning_if_operation_failed "$?"
#=====================================================================
