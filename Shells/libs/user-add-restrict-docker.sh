change_owner_root() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Inputs length is not valid."
        return 1
    fi

    path=$1
    access_number=$2
    is_dir=$3 #true/false

    if [ -f "$path" ]; then
        echo "Remove file: $path"
        sudo rm "$path"
    else
        if [ -d "$path" ]; then
            echo "Remove Directory: $path"
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
    echo "Can not find user-add.sh library." >&2
    exit 1
fi
#================================================================================
echo "Prepairing..."
sudo apt install uidmap && sudo systemctl disable --now docker.service docker.socket && sudo apt-get install -y docker-ce-rootless-extras

sudo /opt/shell-libs/user-add.sh "$username"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit $?
fi
echo "================================================================================"
echo ""

echo "Get server ip..."
server_ip="$(dig +short myip.opendns.com @resolver1.opendns.com)"

echo "ssh -t "$username@$server_ip""
ssh -t "$username@$server_ip" "dockerd-rootless-setuptool.sh install && systemctl --user start docker && systemctl --user enable docker"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit $?
fi
echo "================================================================================"
echo ""

echo "enable-linger..."
sudo loginctl enable-linger "$username"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit $?
fi

echo "Change bash to rbash..."
sudo usermod --shell /bin/rbash "$username"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit $?
fi
echo "================================================================================"
echo ""

home_dir="/home/$username"

#Creates bin dir & Configs permission
bin_dir="$home_dir/bin"
echo "change_owner_root "$bin_dir""
change_owner_root "$bin_dir" 755 "true"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit "$?"
fi

#Creates .profile & Configs permission
profile_file="$home_dir/.profile"
echo "change_owner_root "$profile_file""
change_owner_root "$profile_file" 644 "false"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit "$?"
fi

#Creates .bashrc & Configs permission
bashrc_file="$home_dir/.bashrc"
echo "change_owner_root "$bashrc_file""
change_owner_root "$bashrc_file" 644 "false"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit "$?"
fi

#Creates .bash_profile & Configs permission
bash_profile_file="$home_dir/.bash_profile"
echo "change_owner_root "$bash_profile_file""
change_owner_root "$bash_profile_file" 644 "false"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit "$?"
fi
echo "================================================================================"
echo ""

echo "Other permissions..."
cache_dir="$home_dir/.cache"
config_dir="$home_dir/.config"
# docker_dir="$home_dir/.docker"
local_dir="$home_dir/.local"

sudo chown root:root "$config_dir" "$local_dir" && sudo chmod 755 "$cache_dir" "$config_dir" "$local_dir"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit "$?"
fi

sudo chown -R root:root "$cache_dir" && sudo chattr -R +i "$cache_dir"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit "$?"
fi

sudo chattr +i "$config_dir" "$local_dir"
echo "================================================================================"
echo ""

echo "Adds commands for user"
sudo chattr -i "$bin_dir"
sudo ln -s /bin/docker "$bin_dir" && sudo ln -s /usr/local/bin/docker-compose "$bin_dir" && sudo ln -s /bin/scp "$bin_dir" && sudo ln -s /bin/rm "$bin_dir" && sudo ln -s /bin/mkdir "$bin_dir" && sudo ln -s /bin/tar "$bin_dir"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit "$?"
fi
sudo chattr +i "$bin_dir"

echo "================================================================================"
echo ""

echo "Adds contents"
chattr -i "$profile_file" "$bash_profile_file" "$bashrc_file"

echo "$(grep ^$username /etc/group)"
printf "Enter user group number (from top line)(like 1000): "
read group_number

echo "# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

readonly PATH=$bin_dir
export DOCKER_HOST=unix:///run/user/$group_number/docker.sock" >>"$profile_file"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit "$?"
fi

echo "if [ -f ~/.profile ]; then
	. ~/.profile
fi" | tee -a "$bash_profile_file" | tee -a "$bashrc_file"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit "$?"
fi

chattr +i "$profile_file" "$bash_profile_file" "$bashrc_file"

#===============================================================================
echo ""
printf "Do you want to login in docker? (y/n): "
read loginToDocker

if [ "$loginToDocker" = "y" ] || [ "$loginToDocker" = "Y" ]; then
    ssh -t "$username@$server_ip" "docker login"
fi
