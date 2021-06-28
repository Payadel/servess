#Get inputs:
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ] || [ -z "$6" ]; then
    if [ ! -z "$1" ]; then
        #Or all or none
        echo "Too few inputs."
        exit 1
    else
        printf "SSL fullchain path (like: fullchain.pem): "
        read ssl_fullchain_path

        printf "SSL private key path (like: privkey.pem): "
        read ssl_privateKey_path

        printf "App domain (like: example.com): "
        read server_name

        printf "Log Directory (default: /var/log/nginx): "
        read log_dir
        if [ -z $log_dir ]; then
            log_dir="/var/log/nginx"
        fi

        printf "App url(proxy pass) (like: http://localhost:3000): "
        read proxy_pass

        printf "Nginx installed directory (default: /etc/nginx): "
        read nginx_dir
        if [ -z $nginx_dir ]; then
            nginx_dir="/etc/nginx"
        fi
    fi
else
    #Inputs are complete
    ssl_fullchain_path=$1
    ssl_privateKey_path=$2
    server_name=$3
    log_dir=$4
    proxy_pass=$5
    nginx_dir=$6
fi

echo ""
curl -s -I $proxy_pass
if [ $? != 0 ]; then
    printf "We have trouble with $proxy_pass. Are you sure proxy pass is valid? (y/n): "
    read isProxyPassValid

    if [ "$isProxyPassValid" != "y" ] && [ "$isProxyPassValid" != "Y" ]; then
        echo "Operation canceled."
        exit 0
    fi
    echo ""
fi

echo "ssl_fullchain_path: $ssl_fullchain_path"
echo "ssl_privateKey_path: $ssl_privateKey_path"
echo "server_name: $server_name"
echo "log_dir: $log_dir"
echo "proxy_pass: $proxy_pass"
echo "nginx_dir: $nginx_dir"

printf "Is data valid? (y/n): "
read isDataValid

if [ "$isDataValid" != "y" ] && [ "$isDataValid" != "Y" ]; then
    echo "Operation canceled."
    exit 0
fi
echo ""

#==============================================================================
configFile_path="$nginx_dir/sites-available/$server_name"
if [ -f "$configFile_path" ]; then
    echo "file $configFile_path is exist"
    exit 1
fi

sudo echo "server {
    listen 443 ssl;
    listen [::]:443 ssl;
    ssl_certificate $ssl_fullchain_path;
    ssl_certificate_key $ssl_privateKey_path;

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
" >>"$configFile_path"

if [ $? == 0 ]; then
    echo "Create file $configFile_path successfull."
else
    echo "Operation failed."
    exit $?
fi

configFile_ln_path="$nginx_dir/sites-enabled/$server_name"
echo "Create ln in $configFile_ln_path..."

if [ -f "$configFile_ln_path" ]; then
    echo "Remove old file..."
    sudo rm "$configFile_ln_path"
fi

sudo ln -s "$configFile_path" "$configFile_ln_path"
if [ $? == 0 ]; then
    echo "Create ln file $configFile_ln_path successfull."
else
    echo "Operation failed."
    exit $?
fi

nginx -t
if [ $? != 0 ]; then
    echo "Error in config file!"
    exit 1
fi

echo "Restart nginx service..."
sudo systemctl restart nginx

if [ $? != 0 ]; then
    echo "Error in config file!"
    exit 1
fi

echo "Done."
