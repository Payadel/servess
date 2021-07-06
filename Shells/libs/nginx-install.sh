add_file_to_motd() {
    local fileName=$1
    local next_number=$2

    sudo ln -s "/opt/shell-libs/$fileName" "/etc/update-motd.d/$next_number-${fileName::-3}"
}

sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx

printf "Do you want see service checks in system welcome messages? (y/n): "
read input

if [ "$input" == "y" ] || [ "$input" == "Y" ]; then
    fileName="nginx-services-check.sh"

    #Check directory
    if [ ! -d "/etc/update-motd.d" ]; then
        echo "Directory /etc/update-motd.d isn't exist."
        echo "Operation failed."
        exit 1
    fi

    #Get last number
    last_file_number=$(ls /etc/update-motd.d | sort -V | tail -n 1 | grep -o "^[0-9]*")
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
        add_file_to_motd "$fileName" ""$new_number""
    fi
fi
