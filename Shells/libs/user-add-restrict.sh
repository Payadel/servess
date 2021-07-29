#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-add.sh ] || [ ! -f /opt/shell-libs/user-get-homeDir.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

printf "Username: "
read username

echo_info "Create user $username..."
/opt/shell-libs/user-add.sh "$username" "n" "n" "y" "n"

echo_info "Change user bash ro rbash..."
chsh -s /bin/rbash "$username"

home_dir=$(/opt/shell-libs/user-get-homeDir.sh "$username")
if [ "$?" != 0 ] || [ -z "$home_dir" ]; then
    printf "User home directory: "
    read home_dir

    if [ ! -d "$home_dir" ]; then
        echo -e "$ERROR_COLORIZED: Invalid directory."
        exit 1
    fi
fi

echo_info "Creates bin dir & Configs permission..."
bin_dir="$home_dir/bin"
sudo mkdir -p "$bin_dir" && chmod 755 "$bin_dir" && chattr +i "$bin_dir"
exit_if_operation_failed "$?"

echo_info "Creates .profile & Configs permission..."
profile="$home_dir/.profile"
if [ -f "$profile" ]; then
    sudo rm "$profile"
fi
echo "readonly PATH=$bin_dir" >>$profile
sudo chown root:root $profile && sudo chmod 644 $profile && chattr +i $profile
exit_if_operation_failed "$?"

echo_info "Creates .bashrc & Configs permission..."
bashrc="$home_dir/.bashrc"
if [ -f "$bashrc" ]; then
    sudo rm "$bashrc"
fi
echo ". $profile" >>$bashrc
sudo chown root:root $bashrc && sudo chmod 644 $bashrc && chattr +i $bashrc
exit_if_operation_failed "$?"

echo_info "Creates .bash_profile & Configs permission..."
bash_profile="$home_dir/.bash_profile"
if [ -f "$bash_profile" ]; then
    sudo rm "$bash_profile"
fi
echo ". $profile" >>$bash_profile
sudo chown root:root $bash_profile && sudo chmod 644 $bash_profile && chattr +i $bash_profile
exit_if_operation_failed "$?"

echo -e "${BOLD_GREEN}You can add command for $username with below command:${ENDCOLOR}"
echo "sudo ln -s /bin/*command* $bin_dir/"
