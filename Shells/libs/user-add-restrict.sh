# sudo ln -s /bin/bash /bin/rbash
echo "Add Restrict User"

#Gets username
printf "Username: "
read username

printf "Use rbash? (y/n): "
read useRbash
if [ useRbash = "y" ] || [ useRbash = "Y" ]; then
    echo "Using rbash..."
    bash="/bin/rbash"
else
    echo "Using bash..."
    bash="/bin/bash"
fi

#Adds user
home_dir="/home/$username"
sudo useradd "$username" -s "$bash" --home-dir "$home_dir"

#Sets password
sudo passwd "$username"

#Creates home dir & Configs permission
if [ -d "$home_dir" ]; then
    sudo rm -r "$home_dir"
fi
sudo mkdir "$home_dir"
sudo chown "$username:$username" "$home_dir"
chmod 750 "$home_dir"

#Creates bin dir & Configs permission
bin_dir="$home_dir/bin"
sudo mkdir -p "$bin_dir"
chmod 755 "$bin_dir"

#Creates bash_profile & Configs permission
bash_profile="$home_dir/.bash_profile"
if [ -f "$bash_profile" ]; then
    sudo rm "$bash_profile"
fi
echo "PATH=$bin_dir" >>$bash_profile
sudo chown root:root $bash_profile
sudo chmod 755 $bash_profile

#Disables welcome banner
sudo touch "$home_dir/.hushlogin"

echo "You can add command for $username with below command:"
echo "sudo ln -s /bin/*command* $bin_dir/"
