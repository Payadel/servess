#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

username="$1"
if [ -z "$username" ]; then
    printf "Username: "
    read username
fi
user_must_exist "$username"

printf "Do you want disable $username password? (y/n): "
read disable_password
if [ "$disable_password" != "y" ] && [ "$disable_password" != "Y" ]; then
    exit 0
fi

servess sshd password --disabled-list --disable-password "$username"
exit_if_operation_failed "$?"

echo_info "Restarting ssh service..."
systemctl restart ssh
show_warning_if_operation_failed "$?"
