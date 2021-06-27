printf "Name: "
read name

home_dir="/home/$name"
sudo adduser --home "$home_dir" "$name"

if [ ! -d "$home_dir" ]; then
    sudo mkdir "$home_dir"
    sudo chown "$name:$name" "$home_dir"
fi
chmod 750 "$home_dir"

#Disables welcome banner
sudo touch "$home_dir/.hushlogin"
chattr +i "$home_dir/.hushlogin"
