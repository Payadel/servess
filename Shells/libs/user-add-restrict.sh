#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

# sudo ln -s /bin/bash /bin/rbash
echo "Add Restrict User"

#Gets username
if [ -z $1 ]; then
    printf "Username: "
    read username
else
    username=$1
fi

#Adds user
home_dir="/home/$username"
sudo useradd "$username" -s "/bin/rbash" --home-dir "$home_dir"

#Sets password
sudo passwd "$username"

#Creates home dir & Configs permission
if [ -d "$home_dir" ]; then
    sudo rm -r "$home_dir"
fi
sudo mkdir "$home_dir" && sudo chown "$username:$username" "$home_dir" && chmod 750 "$home_dir"
exit_if_operation_failed "$?"

#Creates bin dir & Configs permission
bin_dir="$home_dir/bin"
sudo mkdir -p "$bin_dir" && chmod 755 "$bin_dir" && chattr +i "$bin_dir"
exit_if_operation_failed "$?"

#Creates .profile & Configs permission
profile="$home_dir/.profile"
if [ -f "$profile" ]; then
    sudo rm "$profile"
fi
echo "readonly PATH=$bin_dir" >>$profile
sudo chown root:root $profile && sudo chmod 644 $profile && chattr +i $profile
exit_if_operation_failed "$?"

#Creates .bashrc & Configs permission
bashrc="$home_dir/.bashrc"
if [ -f "$bashrc" ]; then
    sudo rm "$bashrc"
fi
echo ". $profile" >>$bashrc
sudo chown root:root $bashrc && sudo chmod 644 $bashrc && chattr +i $bashrc
exit_if_operation_failed "$?"

#Creates .bash_profile & Configs permission
bash_profile="$home_dir/.bash_profile"
if [ -f "$bash_profile" ]; then
    sudo rm "$bash_profile"
fi
echo ". $profile" >>$bash_profile
sudo chown root:root $bash_profile && sudo chmod 644 $bash_profile && chattr +i $bash_profile
exit_if_operation_failed "$?"

#Disables welcome banner
sudo touch "$home_dir/.hushlogin" && chattr +i "$home_dir/.hushlogin"
exit_if_operation_failed "$?"

echo -e "${BOLD_GREEN}You can add command for $username with below command:${ENDCOLOR}"
echo "sudo ln -s /bin/*command* $bin_dir/"
