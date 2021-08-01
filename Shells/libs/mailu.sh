#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-add-restrict-docker.sh ] || [ ! -f /opt/shell-libs/user-get-homeDir.sh ] || [ ! -f /opt/shell-libs/nginx-add-app.sh ] || [ ! -f /opt/shell-libs/ip-current.sh ] || [ ! -f /opt/shell-libs/ufw-mailu.sh ] || [ ! -f /opt/shell-libs/password-generate.sh ] || [ ! -f /opt/shell-libs/user-group-number.sh ] || [ ! -f /opt/shell-libs/user-config.sh ]; then
  echo "Can't find libs." >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

copy_file() {
  local file="$1"
  local output="$2"
  local username="$3"

  sudo cp "$file" "$output" && sudo chown "$username:$username" "$file"
}

get_and_copy_file() {
  local fileName="$1"
  local output="$2"
  local username="$3"

  while true; do
    printf "%s file: " "$fileName"
    read -r file
    if [ -f "$file" ]; then
      copy_file "$file" "$output" "$username"
      break
    fi
    echo_error "Can not find file: $file"
  done
}

port_must_free() {
  local port="$1"

  while true; do
    result=$(sudo lsof -i:"$port")
    if [ "$?" != 0 ] && [ -z "$result" ]; then
      break
    fi
    echo_error "Port $port is not free. Press enter to check again..."
    read -r temp
  done
}

add_a_record_dns_task() {
  user_task "Create A record DNS:     mail    Your IP address"
  mail_ipAddress=$(nslookup -type=A "mail.$domain" | grep "Address:" | gawk -F: '{ print $2 }' | sed -n 2p)
  if [ "$?" != 0 ] || [ -z "$mail_ipAddress" ]; then
    echo_warning "We have trouble with DNS!"
    user_task "Ensure DNS is correct."
  else
    echo_info "Looks good."
  fi
}

add_mx_record_dns_task() {
  user_task "Create MX record DNS:     @    mail.$domain"
  mx_record=$(nslookup -type=MX "$domain" | grep $domain | grep mail.$domain)
  if [ "$?" != 0 ] || [ -z "$mx_record" ]; then
    echo_warning "We have trouble with MX DNS record"
    user_task "Ensure DNS is correct."
  else
    echo_info "Looks good."
  fi
}

ensure_ports_are_free() {
  echo_info "Check ports..."
  port_must_free "2500"
  port_must_free "8081"
  port_must_free "8443"
  port_must_free "1100"
  port_must_free "1430"
  port_must_free "4650"
  port_must_free "5870"
  port_must_free "9930"
  port_must_free "9950"
}

config_nginx() {
  nginx_dir="/etc/nginx"

  while true; do
    if [ ! -d "$nginx_dir" ]; then
      echo_error "Can not find nginx directory in $nginx_dir"
      printf "Input nginx directory path: "
      read -r nginx_dir
    else
      break
    fi
  done

  nginx_config_file="$nginx_dir/nginx.conf"
  mailu_config_title="#Mailu Config"
  mailu_config_data=$(cat "$nginx_config_file" | grep "$mailu_config_title")
  if [ -n "$mailu_config_data" ]; then
    return 0
  fi

  echo_info "Updating $nginx_config_file..."
  echo "
$mailu_config_title
stream
{
    server
    {
            listen 25;
            proxy_pass localhost:2500;
    }

    server
    {
            listen 465;
            proxy_pass localhost:4650;
    }

    server
    {
            listen 587;
            proxy_pass localhost:5870;
    }

    server
    {
            listen 110;
            proxy_pass localhost:1100;
    }

	server
    {
            listen 995;
            proxy_pass localhost:9950;
    }

	server
    {
            listen 143;
            proxy_pass localhost:1430;
    }

	server
    {
            listen 993;
            proxy_pass localhost:9930;
    }
}
" >>"$nginx_config_file"
}

check_spf_dns_record() {
  echo_info "Checking SPF record..."
  spf_record=$(nslookup -type=txt "$domain" | grep "$domain" | grep v=spf)
  if [ "$?" != 0 ] || [ -z "$spf_record" ]; then
    echo_warning "We have trouble with SPF DNS record"
    user_task "Ensure DNS is correct."
  else
    echo_info "Looks good."
  fi
}

check_dkim_dns_record() {
  echo_info "Checking DKIM record..."
  dkim_record=$(nslookup -type=txt dkim._domainkey."$domain" | grep dkim._domainkey."$domain")
  if [ "$?" != 0 ] || [ -z "$dkim_record" ]; then
    echo_warning "We have trouble with DKIM DNS record"
    user_task "Ensure DNS is correct."
  else
    echo_info "Looks good."
  fi
}

check_dmarc_dns_record() {
  echo_info "Cheching DMARC record..."
  dmarc_record=$(nslookup -type=txt _dmarc."$domain" | grep _dmarc."$domain")
  if [ "$?" != 0 ] || [ -z "$dmarc_record" ]; then
    echo_warning "We have trouble with DMARC DNS record"
    user_task "Ensure DNS is correct."
  else
    echo_info "Looks good."
  fi
}

domain="$1"
if [ -z "$domain" ]; then
  printf "Your domain (like example.com): "
  read -r domain
fi

username="$2"
admin_password="$3"
docker_compose_file="$4"
mailu_env_file="$5"
privateKey_file="$6"
fullchain_file="$7"

add_a_record_dns_task
echo ""

add_mx_record_dns_task
echo ""

#Check ports
ensure_ports_are_free

#Config firewall
echo_info "Config firewall..."
/opt/shell-libs/ufw-mailu.sh "enable"
exit_if_operation_failed "$?"
echo ""

echo_info "Create user for mail services..."
if [ -z "$username" ]; then
  printf "Username: "
  read -r username
fi

/opt/shell-libs/user-add-restrict-docker.sh "$username"
exit_if_operation_failed "$?"

#Find user home dir
homeDir=$(/opt/shell-libs/user-get-homeDir.sh "$username")
if [ "$?" != 0 ] || [ -z "$homeDir" ]; then
  echo_error "Can't detect user home directory."
  printf "User home directory: "
  read -r homeDir

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

if [ -z "$docker_compose_file" ] || [ ! -f "$docker_compose_file" ]; then
  get_and_copy_file "docker-compose" "$homeDir/" "$username"
else
  copy_file "$docker_compose_file" "$homeDir/" "$username"
fi
delete_user_if_operation_failed "$?"

if [ -z "$mailu_env_file" ] || [ ! -f "$mailu_env_file" ]; then
  get_and_copy_file "mailu.env" "$homeDir/" "$username"
else
  copy_file "$mailu_env_file" "$homeDir/" "$username"
fi
delete_user_if_operation_failed "$?"

echo_info "Create directory for volumes..."
mkdir "$homeDir/mailu" && sudo chown "$username:$username" "$homeDir/mailu"
delete_user_if_operation_failed "$?"
echo ""

#Change secret key
echo_warning "You should change secret keys in mailu.env file:"
cat "$homeDir/mailu.env" | grep SECRET_KEY
cat "$homeDir/mailu.env" | grep DB_PW
random_pass=$(/opt/shell-libs/password-generate.sh 12)
echo_info "Random password: $random_pass"
printf "Press enter to continue...."
read -r _
nano "$homeDir/mailu.env"
echo ""

#Create restart.sh
restart_docker_shell="restart-docker.sh"
echo_info "Create $restart_docker_shell..."
sudo chattr -i "$homeDir/bin" && echo "docker-compose down && docker-compose -p mailu up -d" >>"$homeDir/bin/$restart_docker_shell" && sudo chmod +x "$homeDir/bin/$restart_docker_shell" && chattr +i "$homeDir/bin"

echo_info "Create sudo-$restart_docker_shell..."
group_number=$(/opt/shell-libs/user-group-number.sh "$username")
sudo mkdir "$homeDir/.sudo" && echo "sudo docker-compose --host unix:///run/user/$group_number/docker.sock down && sudo docker-compose --host unix:///run/user/$group_number/docker.sock  -p mailu up -d" >>"$homeDir/.sudo/$restart_docker_shell" && sudo chmod +x "$homeDir/.sudo/$restart_docker_shell" && chmod 750 "$homeDir/.sudo" && chattr +i "$homeDir/.sudo"

show_warning_if_operation_failed "$?"
echo ""

mkdir -p "$homeDir/mailu/certs" && sudo chown "$username:$username" "$homeDir/mailu/certs" && sudo chmod 750 "$homeDir/mailu/certs"
show_warning_if_operation_failed "$?"

#Copy cert files:
if [ -z "$privateKey_file" ] || [ ! -f "$privateKey_file" ]; then
  get_and_copy_file "privkey.pem" "$homeDir/mailu/certs/key.pem" "$username"
else
  copy_file "$privateKey_file" "$homeDir/mailu/certs/key.pem" "$username"
fi
show_warning_if_operation_failed "$?"

if [ -z "$fullchain_file" ] || [ ! -f "$fullchain_file" ]; then
  get_and_copy_file "fullchain.pem" "$homeDir/mailu/certs/cert.pem" "$username"
else
  copy_file "$fullchain_file" "$homeDir/mailu/certs/cert.pem" "$username"
fi
show_warning_if_operation_failed "$?"
echo ""

#Config nginx
config_nginx
exit_if_operation_failed "$?"
echo ""

echo_info "Running containers with docker-compose..."

echo_info "Get server ip..."
server_ip="$(/opt/shell-libs/ip-current.sh)"

#Get Current Port
ssh_port=$(/opt/shell-libs/ssh-port-current.sh)
if [ "$?" != 0 ]; then
  echo_error "Can not detect ssh port."
  printf "SSH Port: "
  read -r ssh_port
fi

echo_info "Add $username to allow ssh list for ssh access.."
echo_warning "Disable ssh access later if you want."
servess sshd ssh-access -aa "$username"

echo "ssh -t -p $ssh_port ""$username"@"$server_ip"""
ssh -t -p "$ssh_port" "$username@$server_ip" "$restart_docker_shell; exit"
exit_if_operation_failed "$?"

echo_info "Sleep 25s to ensure all containers are run..."
sleep 25s
echo ""

#Generate random password
password=$(/opt/shell-libs/password-generate.sh)
echo_info "Random password: $password"

if [ -z "$admin_password" ]; then
  echo_info "Set password for admin@$domain..."
  printf "Password for admin@%s: " "$domain"
  read -r admin_password
fi

echo_info "dcoker-compose up..."
sudo docker-compose --host unix:///run/user/$group_number/docker.sock -p mailu exec admin flask mailu admin admin $domain $admin_password
show_warning_if_operation_failed "$?"
echo ""

echo_info "Config user..."
/opt/shell-libs/user-config.sh

echo_info "Config nginx..."
/opt/shell-libs/nginx-add-app.sh "mail.$domain" "/var/log/nginx" "https://localhost:8443" "/etc/nginx"
echo ""

user_task "Go to https://mail.$domain/admin, section mail domains, Click un detain button, Then click on Generate Keys button to generate keys."
echo ""

user_task "Create TXT record DNS:     @    SPF value"
echo ""

user_task "Create TXT record DNS:     dkim._domainkey.$domain   DKIM value"
echo ""

user_task "Create TXT record DNS:     _dmarc.$domain   DMARC value"
echo ""

user_task "Ensure send and receive email are correct."
echo ""

user_task "Change admin password if is necessary."
echo ""

#SPF
check_spf_dns_record
echo ""

#DKIM
check_dkim_dns_record
echo ""

#DMARC
check_dmarc_dns_record
echo ""

user_task "You can check email with https://mxtoolbox.com/deliverability/"
