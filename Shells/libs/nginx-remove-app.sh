if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

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

there_must_be_a_site() {
    local sites_available_dir="$1"
    local sites_enabled_dir="$2"

    available_sites_count=$(ls "$sites_available_dir" | wc -l)
    enabled_sites_count=$(ls "$sites_enabled_dir" | wc -l)
    if [[ ! -d "$sites_available_dir" && ! -d "$sites_enabled_dir" ]] ||
        [[ "$available_sites_count" == 0 && "$enabled_sites_count" == 0 ]]; then

        echo -e "${BOLD_YELLOW}There are no any site for delete.${ENDCOLOR}"
        echo "$sites_available_dir and $sites_enabled_dir were checked."
        echo "Operation canceled."
        exit 0
    fi
}

if [ -z "$1" ] || [ -z "$2" ]; then
    #One or all inputs empty
    if [ ! -z "$1" ]; then
        #Too few arguments
        echo -e "$ERROR_COLORIZED: Too few arguments." >&2
        exit 1
    else
        #Get arguments from terminal
        nginx_dir="/etc/nginx"
        printf "Nginx directory (default: $nginx_dir): "
        read input
        if [ ! -z $input ]; then
            nginx_dir="$input"
        fi

        sites_available_dir="$nginx_dir/sites-available"
        sites_enabled_dir="$nginx_dir/sites-enabled"

        #is there any site?
        there_must_be_a_site "$sites_available_dir" "$sites_enabled_dir"

        echo ""
        echo -e "${BOLD_GREEN}Enabled sites: ${ENDCOLOR}"
        ls -lh "$sites_enabled_dir"
        echo ""

        printf "Input site(file) name: "
        read target_fileName
    fi
else
    #Get agruments from command line
    nginx_dir="$1"
    sites_available_dir="$nginx_dir/sites-available"
    sites_enabled_dir="$nginx_dir/sites-enabled"

    #is there any site?
    there_must_be_a_site "$sites_available_dir" "$sites_enabled_dir"

    target_fileName="$2"
fi

if [ -f "$sites_enabled_dir/$target_fileName" ]; then
    fileName="$sites_enabled_dir/$target_fileName"
else
    if [ -f "$sites_available_dir/$target_fileName" ]; then
        fileName="$sites_available_dir/$target_fileName"
    else
        echo -e "$ERROR_COLORIZED: Input is not valid. The file not found." >&2
        exit 1
    fi
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

show_warning_if_operation_failed "$?"

access_log=$(awk -F ' ' -v key="access_log" '$1==key {print $2}' "$fileName")
delete "access log" "$access_log" "f"
show_warning_if_operation_failed "$?"

error_log=$(awk -F ' ' -v key="error_log" '$1==key {print $2}' "$fileName")
delete "error log" "$error_log" "f"
show_warning_if_operation_failed "$?"

if [ -f "$sites_enabled_dir/$target_fileName" ]; then
    echo_info "Removing $sites_enabled_dir/$target_fileName..."
    sudo rm "$sites_enabled_dir/$target_fileName"

    show_warning_if_operation_failed "$?"
fi

if [ -f "$sites_available_dir/$target_fileName" ]; then
    echo_info "Removing $sites_available_dir/$target_fileName..."
    sudo rm "$sites_available_dir/$target_fileName"

    show_warning_if_operation_failed "$?"
fi

echo_info "Restarting nginx service..."
sudo systemctl restart nginx
show_warning_if_operation_failed "$?"

echo -e "$DONE_COLORIZED"

curl_test=$(curl -s -I $proxy_pass)

echo ""
show_warning_if_operation_failed "$?" "$WARNING_COLORIZED: $proxy_pass is still running. Terminate it."
