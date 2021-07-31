if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs" >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

motd_directory="/etc/update-motd.d"

add_file_to_motd() {
    local fileName="$1"
    local next_number="$2"

    local output="$motd_directory/$next_number-${fileName::-3}"

    echo_info "Creating shortcut from $fileName to $output."
    sudo ln -s "$fileName" "$output"
}

fileName="$1"
if [ -z "$fileName" ]; then
    printf "fileName: "
    read fileName
fi

#Check directory
if [ ! -d "$motd_directory" ]; then
    echo_warning "Directory $motd_directory isn't exist."
    echo_info "Creating directory..."
    sudo mkdir -p "$motd_directory"
fi

#Get last number
last_file_number=$(ls $motd_directory | sort -V | tail -n 1 | grep -o "^[0-9]*")
last_number_length=${#last_file_number}

#Get new number
next_number=$(($last_file_number + 1))
next_number_length=${#next_number}

if [ "$last_number_length" == "$next_number_length" ]; then
    # last number: 98 --> new number: 99
    add_file_to_motd "$fileName" "$next_number"
else
    # last number: 99 --> new number: 900
    new_number="9"
    for ((i = 0; i < $last_number_length; i++)); do
        new_number="${new_number}0"
    done
    add_file_to_motd "$fileName" "$new_number"
fi
