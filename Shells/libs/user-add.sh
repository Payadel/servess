printf "Name: "
read name

sudo adduser "$name"
chmod 750 "/home/$name"
