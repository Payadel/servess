if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

fileOrDir_must_exist() {
    local path="$1"
    local type="$2"
    if [ "$type" != "d" ] && [ "$type" != "f" ]; then
        echo_error "input is not valid. type must be d for directory or f for file." >&2
        exit 1
    fi

    if [ ! -$type $path ]; then
        echo_error "Can not find $path."
        exit 1
    fi
}

proxy_must_valid() {
    local proxy_pass="$1"

    curl_result=$(curl -s -I --insecure "$proxy_pass")
    if [ $? != 0 ]; then
        printf "We have trouble with $proxy_pass. Are you sure proxy pass is valid? (y/n): "
        read isProxyPassValid

        if [ "$isProxyPassValid" != "y" ] && [ "$isProxyPassValid" != "Y" ]; then
            echo_warning "Operation canceled."
            exit 0
        fi
        echo ""
    fi
}

rollback_operations() {
    local nginx_dir="$1"
    local server_name="$2"

    printf "Do you want remove files? (y/n): "
    read input

    if [ "$input" = "y" ] || [ "$input" = "Y" ]; then
        /opt/shell-libs/nginx-remove-app.sh "$nginx_dir" "$server_name"
    fi
}

echo_keyValue_data() {
    local key=$1
    local value=$2

    if [ -z "$value" ]; then
        echo -e "$key: ${BOLD_YELLOW}Empty${ENDCOLOR}"
    else
        echo "$key: $value"
    fi

}

#Get inputs:
if [ "$#" -eq 4 ]; then # 2 arguments of 6 arguments is optional.
    server_name=$1
    log_dir=$2

    proxy_pass=$3

    proxy_must_valid "$proxy_pass"
    is_https=$(echo "$proxy_pass" | grep "^https://")
    if [ -z "$is_https" ]; then
        #User uses http while ssl isn't set.
        echo_warning "You don't use ssl config."
    fi

    nginx_dir=$4
    fileOrDir_must_exist "$nginx_dir" "d"
else
    if [ "$#" -eq 6 ]; then
        #Inputs are complete
        server_name=$1
        log_dir=$2

        proxy_pass=$3

        proxy_must_valid "$proxy_pass"
        is_https=$(echo "$proxy_pass" | grep "^https://")
        if [ ! -z "$is_https" ]; then
            #User uses https while ssl config is set.
            echo_warning "You are using ssl config but your proxy pass is https!"
        fi

        nginx_dir=$4
        fileOrDir_must_exist "$nginx_dir" "d"

        ssl_fullchain_path=$5
        fileOrDir_must_exist "$ssl_fullchain_path" "f"

        ssl_privateKey_path=$6
        fileOrDir_must_exist "$ssl_privateKey_path" "f"
    else
        if [ "$#" != 0 ]; then
            #Or all or none
            echo_error "Mismatch inputs."
            exit 1
        fi

        printf "App url(proxy pass) (like: http://localhost:3000): "
        read proxy_pass
        proxy_must_valid "$proxy_pass"

        is_https=$(echo "$proxy_pass" | grep "^https://")
        if [ -z "$is_https" ]; then
            #User uses http and may want config ssl.
            printf "Need ssl config? (y/n): "
            read need_ssl
            if [ "$need_ssl" = "y" ] || [ "$need_ssl" = "Y" ]; then
                printf "SSL fullchain path (like: fullchain.pem): "
                read ssl_fullchain_path
                fileOrDir_must_exist "$ssl_fullchain_path" "f"

                printf "SSL private key path (like: privkey.pem): "
                read ssl_privateKey_path
                fileOrDir_must_exist "$ssl_privateKey_path" "f"
            fi
        fi

        printf "App domain (like: example.com): "
        read server_name

        printf "Log Directory (default: /var/log/nginx): "
        read log_dir
        if [ -z $log_dir ]; then
            log_dir="/var/log/nginx"
        fi

        printf "Nginx directory (default: /etc/nginx): "
        read nginx_dir
        if [ -z $nginx_dir ]; then
            nginx_dir="/etc/nginx"
        fi
        fileOrDir_must_exist "$nginx_dir" "d"
    fi
fi
#=======================================================================================
echo ""

#Validations
echo_keyValue_data "ssl_fullchain_path" "$ssl_fullchain_path"
echo_keyValue_data "ssl_privateKey_path" "$ssl_privateKey_path"
echo_keyValue_data "server_name" "$server_name"
echo_keyValue_data "log_dir" "$log_dir"
echo_keyValue_data "proxy_pass" "$proxy_pass"
echo_keyValue_data "nginx_dir" "$nginx_dir"

printf "Is data valid? (y/n): "
read isDataValid

if [ "$isDataValid" != "y" ] && [ "$isDataValid" != "Y" ]; then
    echo_warning "Operation canceled."
    exit 0
fi
echo ""

#Config file
configFile_path="$nginx_dir/sites-available/$server_name"
if [ -f "$configFile_path" ]; then
    printf "file $configFile_path is exist. Replace it? (y/n): "
    read replaceFile

    if [ "$replaceFile" != "y" ] && [ "$replaceFile" != "Y" ]; then
        echo_error "Operation canceled."
        exit 0
    fi

    sudo rm "$configFile_path"
    exit_if_operation_failed "$?" "$ERROR_COLORIZED: Can't remove $configFile_path"
fi
#==============================================================================
#Start...

configFile_data="server {
    listen 443 ssl;
    listen [::]:443 ssl;"

if [ ! -z "$ssl_fullchain_path" ]; then
    configFile_data="$configFile_data
    ssl_certificate $ssl_fullchain_path;
    ssl_certificate_key $ssl_privateKey_path;"
fi

configFile_data="$configFile_data

    server_name $server_name;

    access_log "$log_dir/$server_name.access.log";
    error_log "$log_dir/$server_name.error.log";
    
    location / {
        proxy_pass $proxy_pass;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}

server {
    if (\$host = $server_name) {
        return 301 https://\$host\$request_uri;
    } # managed by Certbot


    listen 80;
    listen [::]:80;

    server_name $server_name;

    return 404; # managed by Certbot
}
"

sudo echo "$configFile_data" >>"$configFile_path"

if [ $? == 0 ]; then
    echo_info "Create file $configFile_path successfull."
else
    echo_error "Operation failed."
    exit $?
fi

configFile_ln_path="$nginx_dir/sites-enabled/$server_name"
echo_info "Create ln in $configFile_ln_path..."

if [ -f "$configFile_ln_path" ]; then
    echo_info "Remove old file..."
    sudo rm "$configFile_ln_path"
fi

sudo ln -s "$configFile_path" "$configFile_ln_path"
if [ $? == 0 ]; then
    echo "Create ln file $configFile_ln_path successfull."
else
    echo_error "Operation failed."

    rollback_operations "$nginx_dir" "$server_name"
    exit $?
fi

nginx -t
if [ $? != 0 ]; then
    echo_error "Error in config file."

    rollback_operations "$nginx_dir" "$server_name"
    exit $?
fi

echo_info "Restart nginx service..."
sudo systemctl restart nginx

exit_if_operation_failed "$?" "$ERROR_COLORIZED: Error in config file!"

echo_success "Done"
