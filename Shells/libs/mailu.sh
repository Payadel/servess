#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-add-restrict-docker.sh ] || [ ! -f /opt/shell-libs/user-get-homeDir.sh ] || [ ! -f /opt/shell-libs/nginx-add-app.sh ] || [ ! -f /opt/shell-libs/ip-current.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

user_task() {
    message="$1"
    printf "Task: $message. Press enter to continue..."
    read temp
}

copy_file() {
    local fileName="$1"
    local output="$2"
    local username="$3"

    while true; do
        printf "$fileName file: "
        read file
        if [ -f "$file" ]; then
            sudo cp "$file" "$output" && sudo chown "$username:$username" "$file"
            break
        fi
        echo_error "Can not find file: $file"
    done
}

port_must_free() {
    local port="$1"

    while true; do
        result=$(sudo lsof -i:$port)
        if [ "$?" != 0 ] && [ -z "$result" ]; then
            break
        fi
        echo_error "Port $port is not free. Press enter to check again..."
        read temp
    done
}

redirect_port() {
    local from="$1"
    local to="$2"

    echo_info "Redirect port $from to $to..."
    iptables -t nat -A PREROUTING -i email-service -p tcp --dport $from -j REDIRECT --to-port $to
}

printf "Your domain (like example.com): "
read domain

user_task "Create A record DNS:     mail    Your IP address"
mail_ipAddress=$(nslookup -type=A "mail.$domain" | grep "Address:" | gawk -F: '{ print $2 }' | sed -n 2p)
if [ "$?" != 0 ] || [ -z "$mail_ipAddress" ]; then
    echo_warning "We have trouble with DNS!"
    user_task "Ensure DNS is correct."
else
    echo_info "Looks good."
fi
echo ""

user_task "Create MX record DNS:     @    mail.$domain"
mx_record=$(nslookup -type=MX "$domain" | grep $domain | grep mail.$domain)
if [ "$?" != 0 ] || [ -z "$mx_record" ]; then
    echo_warning "We have trouble with MX DNS record"
    user_task "Ensure DNS is correct."
else
    echo_info "Looks good."
fi
echo ""

#Config firewall
echo_info "Config firewall..."
sudo ufw allow 25,80,443,110,143,465,587,993,995/tcp
exit_if_operation_failed "$?"
echo ""

echo_info "Create user for mail services..."
printf "Username: "
read username

/opt/shell-libs/user-add-restrict-docker.sh "$username"
exit_if_operation_failed "$?"

#Find user home dir
homeDir=$(/opt/shell-libs/user-get-homeDir.sh "$username")
if [ "$?" != 0 ] || [ -z "$homeDir" ]; then
    echo_error "Can't detect user home directory."
    printf "User home directory: "
    read homeDir

    if [ ! -d "$homeDir" ]; then
        echo_error "Invalid directory."
        exit 1
    fi
else
    echo_info "User home directory detected: $homeDir"
fi
echo ""

user_task "Go to https://setup.mailu.io/ and download setup files if haven't those files."
echo ""

copy_file "docker-compose" "$homeDir/" "$username"
delete_user_if_operation_failed "$?"

copy_file "mailu.env" "$homeDir/" "$username"
delete_user_if_operation_failed "$?"

echo_info "Create directory for volumes..."
mkdir "$homeDir/mailu" && sudo chown "$username:$username" "$homeDir/mailu"
delete_user_if_operation_failed "$?"
echo ""

#Change secret key
echo_warning "You should change secret key in mailu.env file:"
cat "$homeDir/mailu.env" | grep SECRET_KEY
printf "Press enter to continue...."
read temp
nano "$homeDir/mailu.env"
echo ""

#Create restart.sh
restart_docker_shell="restart-docker.sh"
sudo chattr -i "$homeDir/bin" && echo "docker-compose down && docker-compose -p mailu up -d" >>"$homeDir/bin/$restart_docker_shell" && sudo chmod +x "$homeDir/bin/$restart_docker_shell" && chattr +i "$homeDir/bin"
show_warning_if_operation_failed "$?"
echo ""

mkdir -p "$homeDir/mailu/certs" && sudo chown "$username:$username" "$homeDir/mailu/certs" && sudo chmod 750 "$homeDir/mailu/certs"
show_warning_if_operation_failed "$?"

#Copy cert files:
copy_file "privkey.pem" "$homeDir/mailu/certs/key.pem" "$username"
show_warning_if_operation_failed "$?"
copy_file "fullchain.pem" "$homeDir/mailu/certs/cert.pem" "$username"
show_warning_if_operation_failed "$?"
echo ""

#Check ports
port_must_free "25"
port_must_free "2500"
port_must_free "8081"
port_must_free "8443"
port_must_free "110"
port_must_free "1100"
port_must_free "143"
port_must_free "1430"
port_must_free "465"
port_must_free "4650"
port_must_free "587"
port_must_free "5870"
port_must_free "993"
port_must_free "9930"
port_must_free "995"
port_must_free "9950"

redirect_port 995 9950 && redirect_port 993 9930 && redirect_port 587 5870 && redirect_port 465 4650 && redirect_port 143 1430 && redirect_port 25 2500 && redirect_port 110 1100
exit_if_operation_failed "$?"
echo ""

echo_info "Get server ip..."
server_ip="$(/opt/shell-libs/ip-current.sh)"

echo_info "Running containers with docker-compose..."
echo "ssh -t "$username@$server_ip""
ssh -t "$username@$server_ip" "$restart_docker_shell; exit"
exit_if_operation_failed "$?"

echo_info "Sleep 25s to ensure all containers are run..."
sleep 25s
echo ""

echo_info "Set password for admin@$domain..."
printf "Password for admin@$domain: "
read admin_password

echo "ssh -t "$username@$server_ip""
ssh -t "$username@$server_ip" "docker-compose -p mailu exec admin flask mailu admin admin $domain $admin_password; exit"
show_warning_if_operation_failed "$?"
echo ""

echo_info "Config nginx..."
/opt/shell-libs/nginx-add-app.sh "mail.$domain" "/var/log/nginx" "https://localhost:8443" "/etc/nginx"
echo ""

user_task "Go to https://mail.$domain/admin, section mail domains, Click on Generate Keys button to generate keys."
user_task "Set DKIM Keys and DMARC to your DNS."

#SPF
echo_info "Cheching SPF record..."
spf_record=$(nslookup -type=txt "$domain" | grep $domain | grep v=spf)
if [ "$?" != 0 ] || [ -z "$spf_record" ]; then
    echo_warning "We have trouble with SPF DNS record"
    user_task "Ensure DNS is correct."
else
    echo_info "Looks good."
fi
echo ""

#DKIM
echo_info "Cheching DKIM record..."
dkim_record=$(nslookup -type=txt dkim._domainkey.$domain | grep dkim._domainkey.$domain)
if [ "$?" != 0 ] || [ -z "$dkim_record" ]; then
    echo_warning "We have trouble with DKIM DNS record"
    user_task "Ensure DNS is correct."
else
    echo_info "Looks good."
fi
echo ""

#DMARC
echo_info "Cheching DMARC record..."
dmarc_record=$(nslookup -type=txt _dmarc.$domain | grep _dmarc.$domain)
if [ "$?" != 0 ] || [ -z "$dmarc_record" ]; then
    echo_warning "We have trouble with DMARC DNS record"
    user_task "Ensure DNS is correct."
else
    echo_info "Looks good."
fi
echo ""

user_task "You can check email with https://mxtoolbox.com/deliverability/"
