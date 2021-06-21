# sudo ln -s /bin/bash /bin/rbash

printf "Username: "
read username

sudo useradd "$username" -s /bin/rbash
sudo passwd "$username"

sudo chmod 750 "/home/$username"
sudo mkdir -p "/home/$username/bin"

bash_profile="/home/$username/.bash_profile"
echo "PATH=$HOME/bin" >>$bash_profile
sudo chown root:root $bash_profile
sudo chmod 755 $bash_profile
