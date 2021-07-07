if [ ! -f /opt/shell-libs/colors.sh ]; then
    echo "Can't find /opt/shell-libs/colors.sh" >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh

if [ -z $1 ]; then
    printf "Username: "
    read username
else
    username=$1
fi

home_dir="/home/$username"
sudo adduser --home "$home_dir" "$username"
if [ $? != 0 ]; then
    echo -e "$ERROR_COLORIZED: Operation failed." >&2
    exit $?
fi

if [ ! -d "$home_dir" ]; then
    sudo mkdir "$home_dir" && sudo chown "$username:$username" "$home_dir"
fi
chmod 750 "$home_dir"
if [ $? != 0 ]; then
    echo -e "$ERROR_COLORIZED: Operation failed." >&2
    exit $?
fi

#Sudo group?
printf "Add user to sudo group? (y/n): "
read sudo_group
if [ "$sudo_group" == "y" ] || [ "$sudo_group" == "Y" ]; then
    sudo usermod -aG sudo "$username"
fi

#root group?
printf "Add user to root group? (y/n): "
read root_group
if [ "$root_group" == "y" ] || [ "$root_group" == "Y" ]; then
    sudo usermod -aG root "$username"
fi

#Disables welcome banner
printf "Disables welcome banner? (y/n): "
read disable_banner
if [ "$disable_banner" == "y" ] || [ "$disable_banner" == "Y" ]; then
    sudo touch "$home_dir/.hushlogin" && chattr +i "$home_dir/.hushlogin"
fi
