change_owner_root() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Inputs length is not valid."
        return 1
    fi

    filename=$1
    access_number=$2

    file="$home_dir/$filename"

    if [ -f "$file" ]; then
        sudo rm "$file"
    else
        if [ -d "$file" ]; then
            sudo rm -r "$file"
        fi
    fi
    sudo chown root:root "$file" && sudo chmod "$access_number" "$file" && sudo chattr +i "$file"
}

#Checks
if [ ! -f "/opt/shell-libs/user-add.sh" ]; then
    echo "Can not find user-add.sh library."
    exit 1
fi
#================================================================================

sudo apt install uidmap && sudo systemctl disable --now docker.service docker.socket && sudo apt-get install -y docker-ce-rootless-extras

printf "Username: "
read username
sudo /opt/shell-libs/user-add.sh "$username"
if [ $? != 0 ]; then
    echo "Operation failed."
    exit 1
fi
#================================================================================

server_ip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
ssh -t "$username@$server_ip" "dockerd-rootless-setuptool.sh install && systemctl --user start docker && systemctl --user enable docker"
if [ $? != 0 ]; then
    echo "Operation failed."
    exit 1
fi
sudo rm .bash_logout && sudo rm .bash_history

sudo loginctl enable-linger "$username"
if [ $? != 0 ]; then
    echo "Operation failed."
    exit 1
fi

sudo usermod --shell /bin/rbash "$username"
if [ $? != 0 ]; then
    echo "Operation failed."
    exit 1
fi
#================================================================================

home_dir="/home/$username"

#Creates bin dir & Configs permission
change_owner_root bin 755
if [ $? != 0 ]; then
    echo "Operation failed."
    exit "$?"
fi

#Creates .profile & Configs permission
change_owner_root ".profile" 644
if [ $? != 0 ]; then
    echo "Operation failed."
    exit "$?"
fi

#Creates .bashrc & Configs permission
change_owner_root ".bashrc" 644
if [ $? != 0 ]; then
    echo "Operation failed."
    exit "$?"
fi

#Creates .bash_profile & Configs permission
change_owner_root ".bash_profile" 644
if [ $? != 0 ]; then
    echo "Operation failed."
    exit "$?"
fi
#================================================================================

#Other permissions
cache_dir="$home_dir/.cache"
config_dir="$home_dir/.config"
docker_dir="$home_dir/.docker"
local_dir="$home_dir/.local"

sudo chown root:root "$cache_dir" "$config_dir" "$docker_dir" "$local_dir" && sudo chmod 755 "$cache_dir" "$cache_dir" "$docker_dir" "$local_dir" && sudo chattr +i "$cache_dir" "$cache_dir" "$docker_dir" "$local_dir"
if [ $? != 0 ]; then
    echo "Operation failed."
    exit "$?"
fi

sudo chown -R root:root "$cache_dir" && chmod 644 "$cache_dir/docker/key.json" && sudo chattr -R +i "$cache_dir"
if [ $? != 0 ]; then
    echo "Operation failed."
    exit "$?"
fi
#================================================================================

#Adds commands for user
sudo ln -s /bin/docker "$bin_dir" && sudo ln -s /bin/scp "$bin_dir" && sudo ln -s /bin/rm "$bin_dir" && sudo ln -s /bin/mkdir "$bin_dir" && sudo ln -s /bin/tar "$bin_dir"
if [ $? != 0 ]; then
    echo "Operation failed."
    exit "$?"
fi

#================================================================================

#Adds contents
echo "# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

readonly PATH=$bin_dir
export DOCKER_HOST=unix:///run/user/1000/docker.sock" >>"$home_dir/.profile"

echo "if [ -f ~/.profile ]; then
	. ~/.profile
fi" | tee -a "$home_dir/.bash_profile" | tee -a "$home_dir/.bashrc"
