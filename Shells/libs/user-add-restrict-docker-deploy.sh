#Get inputs
if [ -z "$1" ]; then
    printf "deploy file name: "
    read deploy_file_name
else
    deploy_file_name=$1
fi

if [ ! -f "$deploy_file_name" ]; then
    echo "File is not exist."
    exit 1
fi

if [ -z "$2" ]; then
    printf "Username: "
    read Username
else
    Username=$2
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
sudo chattr -i "$user_bin_dir"

cp "$deploy_file_name" "$user_bin_dir/"
sudo chmod 755 deploy-users.sh

sudo chattr +i "$user_bin_dir"
echo "============================================================="
echo ""

echo "Create volume in $volume_dir..."
sudo mkdir -p "$volume_dir"
sudo chown "$username:$username" "$volume_dir"
sudo chmod 750 "$volume_dir"
