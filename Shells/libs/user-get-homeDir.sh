username="$1"
if [ -z "$username" ]; then
    printf "Username: "
    read username
fi

is_user_exist "$username"
if [ "$?" != 0 ]; then
    echo "Invalid username."
    exit 1
fi

getent passwd "$username" | cut -d: -f6
