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

allow_ssh="$2"

if [ -z "$allow_ssh" ]; then
  printf "Allow %s to access ssh? (y/n): " "$username"
  read -r allow_ssh
fi

allowUsers=$(servess sshd ssh-access --list-allow-users | gawk -F ': ' '{ print $2 }')
denyUsers=$(servess sshd ssh-access --list-deny-users | gawk -F ': ' '{ print $2 }')
if [ "$allow_ssh" = "y" ] || [ "$allow_ssh" = "Y" ]; then
  if [ -n "$allowUsers" ]; then
    echo_info "Adding user to allow ssh access list..."
    servess sshd ssh-access --add-allow-user "$username" --list-allow-users
  fi
  if [ -n "$denyUsers" ]; then
    echo_info "Removing user from deny ssh access list..."
    servess sshd ssh-access --remove-deny-user "$username" --list-deny-users
  fi
else
  if [ -n "$allowUsers" ]; then
    echo_info "Removing user from allow ssh access list..."
    servess sshd ssh-access --remove-allow-user "$username" --list-allow-users
  fi
  if [ -n "$denyUsers" ]; then
    echo_info "Adding user to deny ssh list..."
    servess sshd ssh-access --add-deny-user "$username" --list-deny-users
  fi
fi

/opt/shell-libs/ssh-restart.sh
show_warning_if_operation_failed "$?"
