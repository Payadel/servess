#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

nginx_dir="/etc/nginx"

while true; do
    if [ ! -d "$nginx_dir" ]; then
        echo_error "Can not find nginx directory in $nginx_dir"
        printf "Input nginx directory path: "
        read nginx_dir
    else
        break
    fi
done

nginx_config_file="$nginx_dir/nginx.conf"

remove_old_tls() {
    if [ ! -z $(cat "$nginx_config_file" | grep "TLSv1") ] || [ ! -z $(cat "$nginx_config_file" | grep "TLSv1.1") ] || [ ! -z $(cat "$nginx_config_file" | grep "TLSv1.2") ]; then
        user_task "Remove old TLS versions like TLSv1, TLSv1.1 TLSv1.2"
    fi
}

remove_old_tls
