#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/sshKey-config.sh ] || [ ! -f /opt/shell-libs/user-delete.sh ] || [ ! -f /opt/shell-libs/user-ssh-access.sh ] || [ ! -f /opt/shell-libs/password-disable.sh ] || [ ! -f /opt/shell-libs/password-generate.sh ] || [ ! -f /opt/shell-libs/ssh-restart.sh ]; then
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

sudo_group="$2"
root_group="$3"
disable_banner="$4"
expire_password="$5"
allow_ssh="$6"
add_ssh_key="$7"
disable_password="$8"
#========================================================================

is_user_exist=$(id "$username" 2>/dev/null)
if [ "$?" = "0" ]; then
  echo_error "The user already exists."
  exit 1
fi

#Home directory
home_dir="/home/$username"
printf "Input user home directory (default: %s): " "$home_dir"
read -r input_home_dir
if [ -n "$input_home_dir" ]; then
  home_dir="$input_home_dir"
fi

if [ -d "$home_dir" ]; then
  printf "Directory %s already exists. do you want delete it? (y/n): " "$home_dir"
  read -r delete_home_dir
  if [ "$delete_home_dir" = "y" ] || [ "$delete_home_dir" = "Y" ]; then
    chattr -R -i "$home_dir" && sudo rm -r "$home_dir"
    exit_if_operation_failed "$?"
  fi
fi

#Generate random password
/opt/shell-libs/password-generate.sh

sudo adduser --home "$home_dir" "$username"
exit_if_operation_failed "$?"

if [ ! -d "$home_dir" ]; then
  sudo mkdir -p "$home_dir"
fi
sudo chown "$username:$username" "$home_dir" && chmod 750 "$home_dir"
delete_user_if_operation_failed "$?"

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
  sudo touch "$home_dir/.hushlogin" && chattr +i "$home_dir/.hushlogin"
  delete_user_if_operation_failed "$?"
fi

#Disables welcome banner
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
