printf "Username: "
read username

/opt/shell-libs/user-add.sh "$username"
sudo usermod -aG sudo "$username"
