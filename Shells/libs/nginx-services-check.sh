validate_proxy_pass() {
    local proxy_pass=$1
    local fileName=$2

    curl_result=$(curl -s -I "$proxy_pass")
    if [ -z "$curl_result" ]; then
        echo "$fileName: Error - We have trouble with $proxy_pass"
    else
        echo "$fileName: OK - $proxy_pass looks good."
    fi
}

validate_root_dir() {
    local root_dir=$1
    local fileName=$2

    if [ -d "$root_dir" ]; then
        echo "$fileName: OK - Root dir found."
    else
        echo "$fileName: Error - Can't find Root dir. ($root_dir)"
    fi
}

validate_nginx_file() {
    local fileName=$1

    proxy_pass=$(awk -F ' ' -v key="proxy_pass" '$1==key {print $2}' "$fileName")
    if [ -z "$proxy_pass" ]; then
        root_dir=$(awk -F ' ' -v key="root" '$1==key {print $2}' "$fileName")
        if [ -z "$root_dir" ]; then
            echo "$fileName: Error - Can't find proxy_pass or root in this file."
        else
            root_dir=${root_dir::-1} #Removes execc ; char in string
            validate_root_dir "$root_dir" "$fileName"
        fi
    else
        proxy_pass=${proxy_pass::-1} #Removes execc ; char in string
        validate_proxy_pass "$proxy_pass" "$fileName"
    fi
}

nginx_status=$(systemctl status nginx 2>/dev/null | grep "Active: ")
if [ -z "$nginx_status" ]; then
    #Can't find Nginx service
    exit 0
else
    echo "Nginx status: ${nginx_status:13}"
fi
echo ""

#Check sites-enabled files
if [ -d "/etc/nginx/sites-enabled" ]; then
    for fileName in /etc/nginx/sites-enabled/*; do
        validate_nginx_file "$fileName"
    done
fi
