#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-get-homeDir.sh ] || [ ! -f /opt/shell-libs/password-enable.sh ] || [ ! -f /opt/shell-libs/user-logout-sessions.sh ] || [ ! -f /opt/shell-libs/ssh-restart.sh ]; then
  echo "Can't find libs." >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

#Get username
if [ -z "$1" ]; then
  printf "Username: "
  read -r username
else
  username=$1
fi

#Check is user exist?

if ! is_user_exist "$username"; then
  echo_error "The user does not exist."
  exit 1
fi

#Find user home dir
homeDir=$(/opt/shell-libs/user-get-homeDir.sh "$username")
if [ "$?" != 0 ] || [ -z "$homeDir" ]; then
  echo_error "Can't detect user home directory."
  printf "User home directory: "
  read -r homeDir

  if [ ! -d "$homeDir" ]; then
    echo_error "Invalid directory."
    exit 1
  fi
else
  echo_info "User home directory detected: $homeDir"
fi

ls -dlh "$homeDir"
echo -e "$WARNING_COLORIZED!"
printf "Are you sure? (y/n): "
read -r confirm_user_dir
if [ "$confirm_user_dir" != "y" ] && [ "$confirm_user_dir" != "Y" ]; then
  echo_info "Operation canceled."
  exit 0
fi
#============================================================================

#log out active sessions
/opt/shell-libs/user-logout-sessions.sh "$username"
exit_if_operation_failed "$?"

#lock user to prevent login again
sudo passwd -l "$username"
show_warning_if_operation_failed "$?"

#Create backup from user directory
printf "do you wand create backup from user data? (y/n): "
read -r create_backup
if [ "$create_backup" = "y" ] || [ "$create_backup" = "Y" ]; then
  backup_dir="/var/server-backups"
  printf "Backup directory (default: %s): " "$backup_dir"
  read -r input
  if [ -n "$input" ]; then
    backup_dir="$input"
  fi

  if [ ! -d "$backup_dir" ]; then
    sudo mkdir -p "$backup_dir" && chmod 640 "$backup_dir"
    exit_if_operation_failed "$?"
  fi

  sudo tar -zcvf "$backup_dir/user_${username}_backup.tgz" "$homeDir"
  exit_if_operation_failed "$?"
fi

/opt/shell-libs/password-enable.sh "$username"
show_warning_if_operation_failed "$?"

printf "do you wand delete user home dir? (y/n): "
read -r delete_user_homeDir
if [ "$delete_user_homeDir" = "y" ] || [ "$delete_user_homeDir" = "Y" ]; then
  _=$(sudo chattr -R -i "$homeDir" 2>/dev/null)
  sudo userdel -r -f "$username"
else
  sudo userdel -f "$username"
fi
exit_if_operation_failed "$?"

#Access ssh
allowUsers=$(servess sshd ssh-access -la | gawk -F ': ' '{ print $2 }')
echo_info "Config ssh access..."
if [ -n "$allowUsers" ]; then
  is_exist=$(servess sshd ssh-access -la | grep -E "(^| )${username}( |$)")
  if [ -n "$is_exist" ]; then
    echo_info "Removing user from allow ssh access list..."
    servess sshd ssh-access -ra "$username" -la
  fi
fi

denyUsers=$(servess sshd ssh-access -ld | gawk -F ': ' '{ print $2 }')
if [ -n "$denyUsers" ]; then
  is_exist=$(servess sshd ssh-access -ld | grep -E "(^| )${username}( |$)")
  if [ -n "$is_exist" ]; then
    echo_info "Removing user from deny ssh access list..."
    servess sshd ssh-access -rd "$username" -ld
  fi
fi
show_warning_if_operation_failed "$?"

echo_info "Restarting ssh..."
/opt/shell-libs/ssh-restart.sh
show_warning_if_operation_failed "$?"
#=======================================================================

echo_success "Done"
