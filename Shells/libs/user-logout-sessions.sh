#!/bin/bash

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
  read -r username
fi
user_must_exist "$username"

logOut_user="$2"

user_sessions=$(pgrep -u $username)
if [ -n "$user_sessions" ]; then
  if [ -z "$logOut_user" ]; then
    printf "%s still login. do you want log out the user? (y/n): " "$username"
    read -r logOut_user
  fi

  if [ "$logOut_user" = "y" ] || [ "$logOut_user" = "Y" ]; then
    sudo killall -9 -u "$username"
    exit_if_operation_failed "$?"
  else
    exit 2
  fi
fi
