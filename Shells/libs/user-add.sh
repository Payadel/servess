if [ -z $1 ]; then
    printf "Username: "
    read username
else
    username=$1
fi

home_dir="/home/$username"
sudo adduser --home "$home_dir" "$username"

if [ ! -d "$home_dir" ]; then
    sudo mkdir "$home_dir"
    sudo chown "$username:$username" "$home_dir"
fi
chmod 750 "$home_dir"

#Disables welcome banner
sudo touch "$home_dir/.hushlogin"
chattr +i "$home_dir/.hushlogin"
