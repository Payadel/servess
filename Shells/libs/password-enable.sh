#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/ssh-restart.sh ]; then
  echo "Can't find libs." >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

username="$1"
if [ -z "$username" ]; then
  printf "Username: "
  read -r username
fi
user_must_exist "$username"

servess sshd password --disabled-list --enable-password "$username"
exit_if_operation_failed "$?"

echo_info "Restarting ssh service..."
/opt/shell-libs/ssh-restart.sh
show_warning_if_operation_failed "$?"
