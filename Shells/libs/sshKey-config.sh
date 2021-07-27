#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-get-homeDir.sh ] || [ ! -f /opt/shell-libs/password-disable.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

user_must_exist() {
    local username="$1"

    is_user_exist "$username"
    if [ "$?" != 0 ]; then
        echo_error "User is not exist"
        exit 1
    fi
}

if [ "$#" -gt 2 ]; then
    echo_error "Too many inputs."
    exit 1
fi

username="$1"
if [ -z "$username" ]; then
    printf "Username: "
    read username
fi
user_must_exist "$username"

public_key="$2"
if [ -z "$public_key" ]; then
    printf "Public Key for $username: "
    read public_key
fi

#Find user home dir
homeDir=$(/opt/shell-libs/user-get-homeDir.sh "$username")
if [ "$?" != 0 ] || [ -z "$homeDir" ]; then
    echo_error "Can't detect user home directory."
    printf "User home directory: "
    read homeDir

    if [ ! -d "$homeDir" ]; then
        echo_error "Invalid directory."
        exit 1
    fi
else
    echo_info "User home directory detected: $homeDir"
fi

ssh_dir="$homeDir/.ssh"
if [ ! -d "$ssh_dir" ]; then
    echo_info "Create directory: $ssh_dir"
    mkdir -p "$ssh_dir"
    exit_if_operation_failed "$?"
fi

file="$ssh_dir/authorized_keys"
echo "$public_key" >>$file
exit_if_operation_failed "$?"

sudo chown -R "$username:$username" "$ssh_dir" && sudo chmod 700 "$ssh_dir" && sudo chmod -R 600 "$file"
exit_if_operation_failed "$?"

echo ""
printf "Do you want disable user password? (y/n): "
read disable_password

if [ "$disable_password" = "y" ] || [ "$disable_password" = "Y" ]; then
    /opt/shell-libs/password-disable.sh "$username"
    exit_if_operation_failed "$?"
fi
