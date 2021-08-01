#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-get-homeDir.sh ]; then
  echo "Can't find libs." >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

if [ "$#" -gt 2 ]; then
  echo_error "Too many inputs."
  exit 1
fi

username="$1"
if [ -z "$username" ]; then
  printf "Username: "
  read -r username
fi
user_must_exist "$username"

public_key="$2"
if [ -z "$public_key" ]; then
  printf "Public Key for %s (empty for generate one-time key): " "$username"
  read -r public_key
fi

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

ssh_dir="$homeDir/.ssh"
if [ ! -d "$ssh_dir" ]; then
  echo_info "Create directory: $ssh_dir"
  mkdir -p "$ssh_dir"
  exit_if_operation_failed "$?"
fi

if [ -z "$public_key" ]; then
  private_key_file="$ssh_dir/temp"
  ssh-keygen -f "$private_key_file" -b 4096
  exit_if_operation_failed "$?"

  public_key_file="$private_key_file.pub"
  public_key=$(cat "$public_key_file")

  echo_warning "Private Key (write it down, as it will never be displayed again): "
  cat "$private_key_file"
  echo_warning "Save private key in safe place."
  sudo rm "$private_key_file"
  exit_if_operation_failed "$?"

  sudo rm "$public_key_file"
fi

file="$ssh_dir/authorized_keys"
echo "$public_key" >>"$file"
exit_if_operation_failed "$?"

sudo chown -R "$username:$username" "$ssh_dir" && sudo chmod 700 "$ssh_dir" && sudo chmod -R 600 "$file"
exit_if_operation_failed "$?"
