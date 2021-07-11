#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

#Get inputs
if [ -z "$1" ]; then
    printf "deploy file name: "
    read deploy_file_name
else
    deploy_file_name=$1
fi

if [ ! -f "$deploy_file_name" ]; then
    echo -e "$ERROR_COLORIZED: File is not exist." >&2
    exit 1
fi

if [ -z "$2" ]; then
    printf "Username: "
    read username
else
    username=$2
fi

if [ -z "$3" ]; then
    printf "volume_dir (like /srv/app-name): "
    read volume_dir
else
    volume_dir=$3
fi

#=============================================================

echo "Create restrict user that supports docker (username: $username)..."
/opt/shell-libs/user-add-restrict-docker.sh "$username"

#Set variables
user_home_dir="/home/$username"
user_bin_dir="$user_home_dir/bin"
echo "============================================================="
echo ""

echo "Copy deploy shell to user bin ($user_bin_dir)..."
sudo chattr -i "$user_bin_dir" && sudo chmod 755 "$deploy_file_name" && sudo cp "$deploy_file_name" "$user_bin_dir/" && sudo chattr +i "$user_bin_dir"

exit_if_operation_failed "$?"
echo "============================================================="
echo ""

echo "Create volume in $volume_dir..."
sudo mkdir -p "$volume_dir" && sudo chown "$username:$username" "$volume_dir" && sudo chmod 750 "$volume_dir"
exit_if_operation_failed "$?"
