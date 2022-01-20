#!/bin/bash

#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/sshKey-config.sh ] || [ ! -f /opt/shell-libs/user-delete.sh ] || [ ! -f /opt/shell-libs/password-generate.sh ]; then
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
#========================================================================

is_user_exist=$(id "$username" 2>/dev/null)
if [ "$?" = "0" ]; then
  echo_error "The user already exists."
  printf "Do you want delete it? (y/n): "
  read -r delete_user
  if [ "$delete_user" != "y" ] && [ "$delete_user" != "Y" ]; then
    exit 1
  fi

  /opt/shell-libs/user-delete.sh "$username"
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
echo ""
password=$(/opt/shell-libs/password-generate.sh)
echo_info "Random password: $password"

sudo adduser --home "$home_dir" "$username"
exit_if_operation_failed "$?"

if [ ! -d "$home_dir" ]; then
  sudo mkdir -p "$home_dir"
fi
sudo chown "$username:$username" "$home_dir" && chmod 750 "$home_dir"
delete_user_if_operation_failed "$?"
