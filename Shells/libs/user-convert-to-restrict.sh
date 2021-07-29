#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-add.sh ] || [ ! -f /opt/shell-libs/user-get-homeDir.sh ]; then
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

if [ -z "$1" ]; then
    printf "Username: "
    read username
else
    username=$1
fi

echo_info "Change user bash ro rbash..."
sudo usermod --shell /bin/rbash "$username"
exit_if_operation_failed "$?"

home_dir=$(/opt/shell-libs/user-get-homeDir.sh "$username")
if [ "$?" != 0 ] || [ -z "$home_dir" ]; then
    printf "User home directory: "
    read home_dir

    if [ ! -d "$home_dir" ]; then
        echo_error "Invalid directory."
        exit 1
    fi
fi

#Creates bin dir & Configs permission
bin_dir="$home_dir/bin"
echo_info "change_owner_root $bin_dir"
change_owner_root "$bin_dir" 755 "true"
exit_if_operation_failed "$?"

#Creates .profile & Configs permission
profile_file="$home_dir/.profile"
echo_info "change_owner_root "$profile_file""
change_owner_root "$profile_file" 644 "false" && echo "readonly PATH=$bin_dir" >>$profile
exit_if_operation_failed "$?"

#Creates .bashrc & Configs permission
bashrc_file="$home_dir/.bashrc"
echo_info "change_owner_root "$bashrc_file""
change_owner_root "$bashrc_file" 644 "false"
exit_if_operation_failed "$?"

#Creates .bash_profile & Configs permission
bash_profile_file="$home_dir/.bash_profile"
echo_info "change_owner_root "$bash_profile_file""
change_owner_root "$bash_profile_file" 644 "false"
exit_if_operation_failed "$?"

echo ""
echo -e "${BOLD_GREEN}You can add command for $username with below command:${ENDCOLOR}"
echo "sudo ln -s /bin/*command* $bin_dir/"
