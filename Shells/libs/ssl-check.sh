#!/bin/bash

if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

sslPaths_file="/root/.ssl/paths"
expire_day=20
expire_day_in_seconds=$((expire_day * 24 * 3600))

if [ ! -f "$sslPaths_file" ]; then
    echo_error "Can't find ssl paths: $sslPaths_file"
    echo_info "Input your ssl paths (like fullchain.pem) to $sslPaths_file"
    exit 1
fi

is_error=0

IFS=$'\n'
for line in $(cat $sslPaths_file); do
    if [ ! -f "$line" ]; then
        echo_error "Can't find ssl file $line."
        is_error=1
        continue
    fi

    validation_result=$(openssl x509 -enddate -noout -in "$line" -checkend $expire_day_in_seconds | grep "Certificate will expire")
    if [ ! -z "$validation_result" ]; then
        echo_warning "Your ssl in $line will expires less than $expire_day days."
        is_error=1
    fi
done

if [ "$is_error" = 0 ]; then
    ssl_count=$(cat -n $sslPaths_file | tail -1 | awk '{print $1}')
    echo -e "SSL: $OK_COLORIZED - looks good. ($ssl_count files found in $sslPaths_file)"
fi
