#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

port="$1"
if [ -z "$port" ]; then
    printf "Port: "
    read port
fi

servess sshd port --port "$port"
if [ "$?" != 0 ]; then
    show_error_if_operation_failed "$?"
else
    echo_info "Restarting ssh..."
    systemctl restart ssh
fi
