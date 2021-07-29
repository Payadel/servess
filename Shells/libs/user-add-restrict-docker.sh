#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-ssh-access.sh ] || [ ! -f /opt/shell-libs/sshKey-config.sh ] || [ ! -f /opt/shell-libs/ip-current.sh ] || [ ! -f /opt/shell-libs/password-disable.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

change_owner_root() {
    if [ "$#" != 3 ]; then
        echo -e "${BOLD_Red}Inner Error${ENDCOLOR}: Too few inputs." >&2
        return 1
    fi

    path=$1
    access_number=$2
    is_dir=$3 #true/false

    if [ -f "$path" ]; then
        echo "Removing file: $path"
        sudo rm "$path"
    else
        if [ -d "$path" ]; then
            echo "Removing Directory: $path"
            sudo rm -r "$path"
        fi
    fi

    if [ "$is_dir" = "true" ]; then
        echo "Create empty directory: $path"
        sudo mkdir "$path"
    else
        echo "Create empty file: $path"
        sudo touch "$path"
    fi

    echo "Change access file $path"
    sudo chown root:root "$path" && sudo chmod "$access_number" "$path" && sudo chattr +i "$path"
    echo "$(ls -l $path)"
    echo ""
}

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

echo_info "Adds commands for user"
sudo chattr -i "$bin_dir"
sudo ln -s /bin/docker "$bin_dir" && sudo ln -s /usr/local/bin/docker-compose "$bin_dir" && sudo ln -s /bin/scp "$bin_dir" && sudo ln -s /bin/rm "$bin_dir" && sudo ln -s /bin/mkdir "$bin_dir" && sudo ln -s /bin/tar "$bin_dir"
exit_if_operation_failed "$?"

sudo chattr +i "$bin_dir"
show_warning_if_operation_failed "$?"

echo "================================================================================"
echo ""

echo_info "Adding contents..."
chattr -i "$profile_file" "$bash_profile_file" "$bashrc_file"

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

echo "if [ -f ~/.profile ]; then
	. ~/.profile
fi" | tee -a "$bash_profile_file" | tee -a "$bashrc_file"
exit_if_operation_failed "$?"

chattr +i "$profile_file" "$bash_profile_file" "$bashrc_file"
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

echo_info "Enabling dcoker service..."
sudo systemctl enable --now docker.service docker.socket
show_warning_if_operation_failed "$?"
