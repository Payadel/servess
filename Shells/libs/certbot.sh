#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

rollback_if_operation_failed() {
    local code="$1"
    local old_ssl_name="$2"
    local domain="$3"

    if [ "$code" = 0 ]; then
        return 0
    fi

    if [ -d "/etc/letsencrypt/live/$old_ssl_name" ]; then
        echo_info "Moving /etc/letsencrypt/live/$old_ssl_name to /etc/letsencrypt/live/$domain..."
        sudo mv "/etc/letsencrypt/live/$old_ssl_name" "/etc/letsencrypt/live/$domain"
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

if [ -d /etc/letsencrypt ]; then
    echo_info "chattr -i /etc/letsencrypt/..."
    sudo chattr -i /etc/letsencrypt/
    echo ""
fi

echo_info "Installing Apps..."
sudo apt install "certbot" "python3-certbot-nginx"
exit_if_operation_failed "$?"
echo ""

if [ -d "/etc/letsencrypt/live/$domain" ]; then
    date=$(date +"%s")
    old_ssl_name="$domain-$date"
    echo_info "Moving /etc/letsencrypt/live/$domain to /etc/letsencrypt/live/$old_ssl_name..."
    sudo mv "/etc/letsencrypt/live/$domain" "/etc/letsencrypt/live/$old_ssl_name"
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

echo_info "chattr +i /etc/letsencrypt/..."
sudo chattr +i /etc/letsencrypt/
show_warning_if_operation_failed "$?"
