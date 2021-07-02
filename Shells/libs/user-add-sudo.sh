if [ -z $1 ]; then
    printf "Username: "
    read username
else
    username=$1
fi

/opt/shell-libs/user-add.sh "$username"
sudo usermod -aG sudo "$username"
