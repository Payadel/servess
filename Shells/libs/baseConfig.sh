#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

if [ -f "/etc/update-motd.d/10-help-text" ]; then
    echo_info "Disabling help-text in welcome message..."
    chmod -x "/etc/update-motd.d/10-help-text"
    show_warning_if_operation_failed "$?"
    echo ""
fi

#SSH Access Config
printf "Add root user to ssh allow access? (y/n) (press n if don't want use ssh access): "
read add_root_to_allow_ssh
if [ "$add_root_to_allow_ssh" = "y" ] || [ "$add_root_to_allow_ssh" = "Y" ]; then
    servess sshd ssh-access --add-allow-user "root" --list-allow-users
    show_warning_if_operation_failed "$?"
fi

if [ -f "/opt/shell-libs/welcome.sh" ]; then
    echo_info "Adding welcome alias to .bashrc for root user..."
    if [ ! -f "/root/.bashrc" ]; then
        touch "/root/.bashrc"
    fi
    echo "alias welcome='/opt/shell-libs/welcome.sh'" >>/root/.bashrc
    show_warning_if_operation_failed "$?"
    echo ""
fi

#SSH Connection Timeout
printf "Do you want config SSH connection timeout? (y/n): "
read ssh_connection_timeout
if [ "$ssh_connection_timeout" = "y" ] || [ "$ssh_connection_timeout" = "Y" ]; then
    ClientAliveInterval=1200
    printf "Client Alive Interval (default: $ClientAliveInterval): "
    read input
    if [ ! -z "$input" ]; then
        ClientAliveInterval="$input"
    fi

    ClientAliveCountMax=3
    printf "Client Alive Count Max (default: $ClientAliveCountMax): "
    read input
    if [ ! -z "$input" ]; then
        ClientAliveCountMax="$input"
    fi

    servess sshd connection-timeout --interval "$ClientAliveInterval" --count-max "$ClientAliveCountMax"
    show_warning_if_operation_failed "$?"
fi
