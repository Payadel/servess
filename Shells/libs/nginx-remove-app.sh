if [ ! -f /opt/shell-libs/colors.sh ]; then
    echo "Can't find /opt/shell-libs/colors.sh" >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh

delete() {
    local name=$1
    local path=$2
    local type=$3 # d for directory and f for file

    if [ "$type" != "d" ] && [ "$type" != "f" ]; then
        echo -e "$ERROR_COLORIZED: Input is not valid. Only d for directory or f for file are valid." >&2
        exit 1
    fi

    if [ -d "$path" ] || [ -f "$path" ]; then
        echo -e "${BOLD_GREEN}$name found: $path ${ENDCOLOR}"
        printf "Do you want delete $name? (y/n): "
        read input

        if [ "$input" = "y" ] || [ "$input" = "Y" ]; then
            if [ "$type" = "d" ]; then
                sudo rm -r "$path"
            else
                sudo rm "$path"
            fi
        fi
    fi
}

nginx_dir="/etc/nginx"
printf "Nginx directory (default: $nginx_dir): "
read input
if [ ! -z $input ]; then
    nginx_dir="$input"
fi

sites_available_dir="$nginx_dir/sites-available"
sites_enabled_dir="$nginx_dir/sites-enabled"

file_counts=$(ls "$sites_enabled_dir" | wc -l)
if [ ! -d "$sites_enabled_dir" ] || [ "$ls "$sites_enabled_dir" | wc -l" = 0 ]; then
    echo "${BOLD_YELLOW}There are no active sites for delete.${ENDCOLOR}"
    echo "Operation canceled."
    exit 0
fi

echo -e "${BOLD_GREEN}Enabled sites: ${ENDCOLOR}"
ls -lh "$sites_enabled_dir"
echo ""

printf "Input site(file) name: "
read target_fileName
fileName="$sites_enabled_dir/$target_fileName"

if [ ! -f "$fileName" ]; then
    echo -e "$ERROR_COLORIZED: Input is not valid." >&2
    exit 1
fi

proxy_pass=$(awk -F ' ' -v key="proxy_pass" '$1==key {print $2}' "$fileName")
if [ -z "$proxy_pass" ]; then
    root_dir=$(awk -F ' ' -v key="root" '$1==key {print $2}' "$fileName")
    if [ ! -z "$root_dir" ]; then
        root_dir=${root_dir::-1} #Removes execc ; char in string
        delete "root dir" "$root_dir" "d"
    fi
else
    proxy_pass=${proxy_pass::-1} #Removes execc ; char in string
fi

if [ $? != 0 ]; then
    echo -e "$WARNING_COLORIZED: Operation failed." >&2
fi

access_log=$(awk -F ' ' -v key="access_log" '$1==key {print $2}' "$fileName")
delete "access log" "$access_log" "f"
if [ $? != 0 ]; then
    echo -e "$WARNING_COLORIZED: Operation failed." >&2
fi

error_log=$(awk -F ' ' -v key="error_log" '$1==key {print $2}' "$fileName")
delete "error log" "$error_log" "f"
if [ $? != 0 ]; then
    echo -e "$WARNING_COLORIZED: Operation failed." >&2
fi

echo "Removing $sites_enabled_dir/$target_fileName..."
sudo rm "$sites_enabled_dir/$target_fileName"
if [ $? != 0 ]; then
    echo -e "$ERROR_COLORIZED: Operation failed." >&2
    exit 1
fi

if [ -f "$sites_available_dir/$target_fileName" ]; then
    echo "Removing $sites_available_dir/$target_fileName..."
    sudo rm "$sites_available_dir/$target_fileName"
fi

echo "Restarting nginx service..."
sudo systemctl restart nginx
if [ $? != 0 ]; then
    echo -e "$WARNING_COLORIZED: Operation failed." >&2
fi

curl -s -I $proxy_pass
if [ $? = 0 ]; then
    echo -e "$WARNING_COLORIZED: $proxy_pass is still running. Terminate it."
fi
