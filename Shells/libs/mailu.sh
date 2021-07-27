#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-add-restrict-docker.sh ] || [ ! -f /opt/shell-libs/user-get-homeDir.sh ] || [ ! -f /opt/shell-libs/nginx-add-app.sh ]; then
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

    printf "$fileName file: "
    read file
    if [ ! -f "$file" ]; then
        echo_error "Can not find file: $file"
        exit 1
    fi
    sudo cp "$file" "$output" && sudo chown "$username:$username" "$file"
}

printf "Your domain (like example.com): "
read domain

user_task "Create A record DNS:     mail    Your IP address"
mail_ipAddress=$(nslookup -type=A "mail.$domain" | grep "Address:" | gawk -F: '{ print $2 }' | sed -n 2p)
if [ "$?" != 0 ] || [ -z "$mail_ipAddress" ]; then
    echo_warning "We have trouble with DNS!"
    user_task "Ensure DNS is correct."
fi

user_task "Create MX record DNS:     @    mail.$domain"
mx_record=$(nslookup -type=MX "$domain" | grep $domain | grep mail.$domain)
if [ "$?" != 0 ] || [ -z "$mx_record" ]; then
    echo_warning "We have trouble with MX DNS record"
    user_task "Ensure DNS is correct."
fi

#Config firewall
echo_info "Config firewall..."
sudo ufw allow 25,80,443,110,143,465,587,993,995/tcp
exit_if_operation_failed "$?"

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

user_task "Go to https://setup.mailu.io/ and download setup files if haven't those files."

copy_file "docker-compose" "$homeDir/"
delete_user_if_operation_failed "$?"

copy_file "mailu.env" "$homeDir/"
delete_user_if_operation_failed "$?"

echo_info "Create directory for volumes..."
mkdir "$homeDir/mailu" && sudo chown "$username:$username" "$homeDir/mailu"
delete_user_if_operation_failed "$?"

#Change secret key
echo_warning "You should change secret key in mailu.env file:"
cat "$homeDir/mailu.env" | grep SECRET_KEY
printf "Press enter to continue...."
nano "$homeDir/mailu.env"

#Create restart.sh
cat "docker-compose down && docker-compose -p mailu up -d" >>"$homeDir/restart.sh"
sudo chown "$username:$username" "$homeDir/restart.sh" && sudo chmod +x "$homeDir/restart.sh"
show_warning_if_operation_failed "$?"

#Copy cert files:
copy_file "privkey.pem" "$homeDir/mailu/certs/key.pem" && copy_file "fullchain.pem" "$homeDir/mailu/certs/cert.pem"
show_warning_if_operation_failed "$?"

echo_info "Running containers with docker-compose..."
docker-compose -p mailu up -d
exit_if_operation_failed "$?"

echo_info "Sleep 15s to ensure all containers are run..."
sleep 15s
echo ""

printf "Password for admin@yourdomain.com: "
read admin_password
docker-compose -p mailu exec admin flask mailu admin admin inlearn.in "$admin_password"
show_warning_if_operation_failed "$?"

user_task "Go to https://yourdomain.com/admin, section mail domains, Click on Generate Keys button to generate keys."
user_task "Set DKIM Keys and DMARC to your DNS."

#SPF
spf_record=$(nslookup -type=txt "$domain" | grep $domain | grep v=spf)
if [ "$?" != 0 ] || [ -z "$spf_record" ]; then
    echo_warning "We have trouble with SPF DNS record"
    user_task "Ensure DNS is correct."
fi

#DKIM
dkim_record=$(nslookup -type=txt dkim._domainkey.$domain | grep dkim._domainkey.$domain)
if [ "$?" != 0 ] || [ -z "$dkim_record" ]; then
    echo_warning "We have trouble with DKIM DNS record"
    user_task "Ensure DNS is correct."
fi

#DMARC
dmarc_record=$(nslookup -type=txt _dmarc.$domain | grep _dmarc.$domain)
if [ "$?" != 0 ] || [ -z "$dmarc_record" ]; then
    echo_warning "We have trouble with DMARC DNS record"
    user_task "Ensure DNS is correct."
fi

echo_info "Config nginx..."
/opt/shell-libs/nginx-add-app.sh "$domain" "/var/log/nginx" "https://localhost:8443" "/etc/nginx"

user_task "You can check email with https://mxtoolbox.com/deliverability/"
