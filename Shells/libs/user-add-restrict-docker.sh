#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-ssh-access.sh ] || [ ! -f /opt/shell-libs/sshKey-config.sh ] || [ ! -f /opt/shell-libs/ip-current.sh ] || [ ! -f /opt/shell-libs/password-disable.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

#Get Inputs
if [ -z "$1" ]; then
    printf "Username: "
    read username
else
    username=$1
fi
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
sudo /opt/shell-libs/user-add.sh "$username" "n" "n" "y" "n" "y" "n"
exit_if_operation_failed "$?"
echo "================================================================================"
echo ""

echo_info "Get server ip..."
server_ip="$(/opt/shell-libs/ip-current.sh)"

echo "ssh -t "$username@$server_ip""
ssh -t "$username@$server_ip" "dockerd-rootless-setuptool.sh install && systemctl --user start docker && systemctl --user enable docker; exit"
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
    read homeDir

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

group_number=$(grep ^$username /etc/passwd | gawk -F: '{ print $3 }')

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
echo ""
printf "Do you want to login in docker? (y/n): "
read loginToDocker

if [ "$loginToDocker" = "y" ] || [ "$loginToDocker" = "Y" ]; then
    ssh -t "$username@$server_ip" "docker login; exit"
fi

#SSH Access
/opt/shell-libs/user-ssh-access.sh "$username"
show_warning_if_operation_failed "$?"

#SSH Key
printf "Do you want add ssh key? (y/n): "
read add_ssh_key
if [ "$add_ssh_key" = "y" ] || [ "$add_ssh_key" = "Y" ]; then
    /opt/shell-libs/sshKey-config.sh "$username"
    show_warning_if_operation_failed "$?"
fi

/opt/shell-libs/password-disable.sh "$username"
show_warning_if_operation_failed "$?"

echo ""
printf "Enable docker service for $(whoami)?"
read enable_service
if [ "$enable_service" = "y" ] || [ "$enable_service" = "Y" ]; then
    echo_info "Enabling dcoker service..."
    sudo systemctl enable --now docker.service docker.socket
    show_warning_if_operation_failed "$?"
fi

echo_success "Done"
