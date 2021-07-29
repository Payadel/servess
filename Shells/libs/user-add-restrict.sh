#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ~ -f /opt/shell-libs/user-convert-to-restrict.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

if [ -z "$1" ]; then
    printf "Username: "
    read username
else
    username=$1
fi

echo_info "Create user $username..."
/opt/shell-libs/user-add.sh "$username" "n" "n" "y" "n"
exit_if_operation_failed "$?"

echo_info "Convert $username to restrict mode..."
/opt/shell-libs/user-convert-to-restrict.sh
delete_user_if_operation_failed "$?"

echo_success "Done"
