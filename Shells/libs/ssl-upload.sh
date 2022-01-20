#!/bin/bash

#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

printf "Host Name: "
read -r host_name

#Upload ssl files
echo "Create directory and set permissions (/etc/letsencrypt)..."
ssh -t "root@$host_name" "sudo mkdir -p /etc/letsencrypt/live && sudo chmod 750 /etc/letsencrypt"
exit_if_operation_failed "$?"

printf "SSL directory (like /etc/letsencrypt/live/example.com): "
read -r ssl_dir_path
if [ ! -d "$ssl_dir_path" ]; then
    echo_error "Directory not found."
    exit 1
fi

echo "Upload SSL files..."
scp -r "$ssl_dir_path" "root@$host_name"":/etc/letsencrypt/live/" && ssh -t "root@$host_name" "sudo chattr +i /etc/letsencrypt"
exit_if_operation_failed "$?"
