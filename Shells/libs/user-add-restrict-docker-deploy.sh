#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-add-restrict-docker.sh ]; then
  echo "Can't find libs." >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

#Get inputs
if [ -z "$1" ]; then
  printf "deploy shells directory: "
  read -r deploy_shells_directory
else
  deploy_shells_directory=$1
fi

if [ ! -d "$deploy_shells_directory" ]; then
  echo_error "Directory is not exist."
  exit 1
fi

if [ -z "$2" ]; then
  printf "Username: "
  read -r username
else
  username=$2
fi

if [ -z "$3" ]; then
  printf "volume_dir (like /srv/app-name): "
  read -r volume_dir
else
  volume_dir=$3
fi

loginToDocker="$4"
allow_ssh="$5"
add_ssh_key="$6"
disable_password="$7"
enable_service="$8"
#=============================================================

echo_info "Create restrict user that supports docker (username: $username)..."
/opt/shell-libs/user-add-restrict-docker.sh "$username" "" "y" "n" "n" "y"
exit_if_operation_failed "$?"

#Set variables
home_dir=$(/opt/shell-libs/user-get-homeDir.sh "$username")
if [ "$?" != 0 ] || [ -z "$home_dir" ]; then
  printf "User home directory: "
  read -r home_dir

  if [ ! -d "$home_dir" ]; then
    echo_error "Invalid directory."
    exit 1
  fi
fi

user_bin_dir="$home_dir/bin"
echo "============================================================="
echo ""

echo_info "Copy deploy shell to user bin ($user_bin_dir)..."
sudo chattr -i "$user_bin_dir" && sudo chmod -R 755 "$deploy_shells_directory" && sudo cp "$deploy_shells_directory"/* "$user_bin_dir/" && sudo chattr +i "$user_bin_dir"

exit_if_operation_failed "$?"
echo "============================================================="
echo ""

echo_info "Create volume in $volume_dir..."
sudo mkdir -p "$volume_dir" && sudo chown "$username:$username" "$volume_dir" && sudo chmod 750 "$volume_dir"
exit_if_operation_failed "$?"

#SSH Access
/opt/shell-libs/user-ssh-access.sh "$username" "$allow_ssh"
show_warning_if_operation_failed "$?"

#SSH Key
if [ -z "$add_ssh_key" ]; then
  printf "Do you want add ssh key? (y/n): "
  read -r add_ssh_key
fi
if [ "$add_ssh_key" = "y" ] || [ "$add_ssh_key" = "Y" ]; then
  /opt/shell-libs/sshKey-config.sh "$username"
  show_warning_if_operation_failed "$?"
fi

/opt/shell-libs/password-disable.sh "$username" "$disable_password"
show_warning_if_operation_failed "$?"

if [ -z "$enable_service" ]; then
  echo ""
  printf "Enable docker service for %s? (y/n): " "$(whoami)"
  read -r enable_service
fi
if [ "$enable_service" = "y" ] || [ "$enable_service" = "Y" ]; then
  echo_info "Enabling dcoker service..."
  sudo systemctl enable --now docker.service docker.socket
  show_warning_if_operation_failed "$?"
fi
