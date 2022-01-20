#!/bin/bash

#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/ip-current.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

letsencrypt_dir="/etc/letsencrypt"

rollback_if_operation_failed() {
    local code="$1"
    local old_ssl_name="$2"
    local domain="$3"

    if [ "$code" = 0 ]; then
        return 0
    fi

    if [ -d "$letsencrypt_dir/live/$old_ssl_name" ]; then
        echo_info "Moving $letsencrypt_dir/live/$old_ssl_name to $letsencrypt_dir/live/$domain..."
        sudo mv "$letsencrypt_dir/live/$old_ssl_name" "$letsencrypt_dir/live/$domain"
        echo ""
    fi
}

domain="$1"
if [ -z "$domain" ]; then
    printf "Domain (like example.com): "
    read -r domain
    echo ""
fi

echo_info "We create ssl for $domain and *.$domain."
printf "Are you sure? (y/n): "
read -r sure
if [ "$sure" != "y" ] && [ "$sure" != "Y" ]; then
    echo_info "Operation canceled."
    exit 0
fi
echo ""

if [ -d "$letsencrypt_dir" ]; then
    echo_info "chattr -i $letsencrypt_dir/..."
    sudo chattr -i "$letsencrypt_dir"
    echo ""
fi

echo_info "Installing Apps..."
sudo apt install "certbot" "python3-certbot-nginx"
exit_if_operation_failed "$?"
echo ""

if [ -d "$letsencrypt_dir/live/$domain" ]; then
    date=$(date +"%s")
    old_ssl_name="$domain-$date"
    echo_info "Moving $letsencrypt_dir/live/$domain to $letsencrypt_dir/live/$old_ssl_name..."
    sudo mv "$letsencrypt_dir/live/$domain" "$letsencrypt_dir/live/$old_ssl_name"
    echo ""
fi

echo_info "Running certbot..."
sudo certbot certonly \
    --agree-tos \
    --manual \
    --preferred-challenges=dns \
    -d *."$domain" \
    -d "$domain" \
    --server https://acme-v02.api.letsencrypt.org/directory
rollback_if_operation_failed "$?"
echo ""

echo_info "chattr +i $letsencrypt_dir/..."
sudo chattr +i "$letsencrypt_dir"
show_warning_if_operation_failed "$?"

echo_success "Done."
echo ""

echo_info "You can create backup in your local system with this command (run this command in your system not in current system): "
server_ip="$(/opt/shell-libs/ip-current.sh)"
if [ "$?" = 0 ]; then
    echo "scp -r $(whoami)@$server_ip:$letsencrypt_dir /local/dir"
    echo_warning "Replace /local/dir with your local address!"
else
    echo "scp -r $(whoami)@HOST:$letsencrypt_dir /local/dir"
    echo_warning "Replace /local/dir with your local address and Replace HOST with your host name (or ip)."
fi
