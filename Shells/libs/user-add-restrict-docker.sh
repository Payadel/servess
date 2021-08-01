#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/ip-current.sh ] || [ ! -f /opt/shell-libs/ssh-port-current.sh ] || [ ! -f /opt/shell-libs/user-group-number.sh ]; then
  echo "Can't find libs." >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

#Get Inputs
if [ -z "$1" ]; then
  printf "Username: "
  read -r username
else
  username=$1
fi

loginToDocker="$2"
enable_service="$3"
#================================================================================

#Checks
if [ ! -f "/opt/shell-libs/user-add.sh" ]; then
  echo_error "Can not find user-add.sh library."
  exit 1
fi
#================================================================================
echo_info "Prepairing..."
sudo apt install uidmap && sudo apt-get install -y docker-ce-rootless-extras
exit_if_operation_failed "$?"

sudo systemctl disable --now docker.service docker.socket

echo_info "Adding user ($username)..."
sudo /opt/shell-libs/user-add.sh "$username"
exit_if_operation_failed "$?"
echo "================================================================================"
echo ""

echo_info "Get server ip..."
server_ip="$(/opt/shell-libs/ip-current.sh)"

#Get Current Port
ssh_port=$(/opt/shell-libs/ssh-port-current.sh)
if [ "$?" != 0 ]; then
  echo_error "Can not detect ssh port."
  printf "SSH Port: "
  read -r ssh_port
fi

echo_info "Add $username to allow ssh list for ssh access.."
echo_warning "Disable ssh access later if you want."
/opt/shell-libs/user-ssh-access.sh "$username" "y"

echo "ssh -t -p $ssh_port ""$username"@"$server_ip"""
ssh -t -p "$ssh_port" "$username@$server_ip" "dockerd-rootless-setuptool.sh install && systemctl --user start docker && systemctl --user enable docker; exit"
exit_if_operation_failed "$?"
echo "================================================================================"
echo ""

echo_info "enable-linger..."
sudo loginctl enable-linger "$username"
exit_if_operation_failed "$?"

echo_info "Convert user to restrict mode..."
/opt/shell-libs/user-convert-to-restrict.sh "$username"

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
fi

bin_dir="$homeDir/bin"
if [ ! -d "$bin_dir" ]; then
  mkdir "$bin_dir"
fi

echo_info "Adds commands for user"
sudo chattr -i "$bin_dir"
sudo ln -s /bin/docker "$bin_dir" && sudo ln -s /usr/local/bin/docker-compose "$bin_dir" && sudo ln -s /bin/scp "$bin_dir" && sudo ln -s /bin/rm "$bin_dir" && sudo ln -s /bin/mkdir "$bin_dir" && sudo ln -s /bin/tar "$bin_dir"
exit_if_operation_failed "$?"

sudo chattr +i "$bin_dir"
show_warning_if_operation_failed "$?"

echo "================================================================================"
echo ""

profile_file="$homeDir/.profile"
echo_info "Adding contents..."
chattr -i "$profile_file"

group_number=$(/opt/shell-libs/user-group-number.sh "$username")

echo "# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

export DOCKER_HOST=unix:///run/user/$group_number/docker.sock" >>"$profile_file"
exit_if_operation_failed "$?"

chattr +i "$profile_file"
show_warning_if_operation_failed "$?"

#===============================================================================
if [ -z "$loginToDocker" ]; then
  echo ""
  printf "Do you want to login in docker? (y/n): "
  read -r loginToDocker
fi
if [ "$loginToDocker" = "y" ] || [ "$loginToDocker" = "Y" ]; then
  ssh -t -p "$ssh_port" "$username@$server_ip" "docker login; exit"
fi

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

echo_success "Done"
