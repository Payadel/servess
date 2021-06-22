printf "Name: "
read name

sudo adduser "$name"

user_dir="/home/$name"
if [ ! -d "$user_dir" ]; then
    mkdir "$user_dir"
    chown "$name:$name" "$name"
fi
chmod 750 "$user_dir"
