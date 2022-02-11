#!/bin/bash

#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-get-homeDir.sh ] || [ ! -f /opt/shell-libs/user-logout-sessions.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

if [ -z "$1" ]; then
    printf "Username: "
    read -r username
else
    username=$1
fi
user_must_exist "$username"

/opt/shell-libs/user-logout-sessions.sh "$username" "y"
exit_if_operation_failed "$?"

echo_info "Change user rbash to bash..."
sudo usermod --shell /bin/bash "$username"
exit_if_operation_failed "$?"

home_dir=$(/opt/shell-libs/user-get-homeDir.sh "$username")
if [ "$?" != 0 ] || [ -z "$home_dir" ]; then
    printf "User home directory: "
    read -r home_dir

    if [ ! -d "$home_dir" ]; then
        echo_error "Invalid directory."
        exit 1
    fi
fi

#User bin dir:
bin_dir="$home_dir/bin"
if [ -d "$bin_dir" ]; then
    printf "Remove %s? (y/n): " "$bin_dir"
    read -r remove_bin_dir

    if [ "$remove_bin_dir" = 'y' ] || [ "$remove_bin_dir" = 'Y' ]; then
        echo_info "Removing '$bin_dir'..."
        sudo chattr -i "$bin_dir"
        sudo rm -r "$bin_dir"
    fi
fi

#Readonly path
profile_file="$home_dir/.profile"
echo_info "Removing readonly path...."
sudo chattr -i "$profile_file"
sudo sed -i "/readonly PATH=/d" "$profile_file"
