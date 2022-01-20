#!/bin/bash

username="$1"
if [ -z "$username" ]; then
    printf "Username: "
    read -r username
fi

grep ^"$username" /etc/passwd | gawk -F: '{ print $3 }'
