#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/user-get-homeDir.sh ] || [ ! -f /opt/shell-libs/user-logout-sessions.sh ]; then
  echo "Can't find libs." >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

change_owner_root() {
  if [ "$#" -lt 3 ]; then
    echo -e "${BOLD_Red}Inner Error${ENDCOLOR}: Too few inputs." >&2
    return 1
  fi

  path="$1"
  access_number=$2
  is_dir=$3 #true/false
  content="$4"

  if [ "$is_dir" = "true" ] && [ -n "$content" ]; then
    echo -e "${BOLD_Red}Inner Error${ENDCOLOR}: Directory can't accept content." >&2
    return 1
  fi

  chattr -i $path
  if [ -f "$path" ]; then
    echo "Removing file: $path"
    sudo rm "$path"
  else
    if [ -d "$path" ]; then
      echo "Removing Directory: $path"
      sudo rm -r "$path"
    fi
  fi

  if [ "$is_dir" = "true" ]; then
    echo "Create empty directory: $path"
    sudo mkdir "$path"
  else
    echo "Create empty file: $path"
    sudo touch "$path"
  fi

  echo "Add content..."
  echo "$content" >>$path

  echo "Change access file $path"
  sudo chown root:root "$path" && sudo chmod "$access_number" "$path" && sudo chattr +i "$path"
  ls -l "$path"
  echo ""
}

if [ -z "$1" ]; then
  printf "Username: "
  read -r username
else
  username=$1
fi
user_must_exist "$username"

/opt/shell-libs/user-logout-sessions.sh "$username" "y"
exit_if_operation_failed "$?"

echo_info "Change user bash ro rbash..."
sudo usermod --shell /bin/rbash "$username"
exit_if_operation_failed "$?"

home_dir=$(/opt/shell-libs/user-get-homeDir.sh "$username")
if [ "$?" != 0 ] || [ -z "$home_dir" ]; then
  printf "User home directory: "
  read -r home_dir

  if [ ! -d "$home_dir" ]; then
    echo_error "Invalid directory."
    exit 1
  fi
fi

#Creates bin dir & Configs permission
bin_dir="$home_dir/bin"
echo_info "change_owner_root $bin_dir"
change_owner_root "$bin_dir" 755 "true"
exit_if_operation_failed "$?"

#Creates .profile & Configs permission
profile_file="$home_dir/.profile"
echo_info "change_owner_root $profile_file"
change_owner_root "$profile_file" 644 "false" "readonly PATH=$bin_dir"
exit_if_operation_failed "$?"

#Creates .bashrc & Configs permission
bashrc_file="$home_dir/.bashrc"
echo_info "change_owner_root $bashrc_file"
change_owner_root "$bashrc_file" 644 "false" ". $profile_file"
exit_if_operation_failed "$?"

#Creates .bash_profile & Configs permission
bash_profile_file="$home_dir/.bash_profile"
echo_info "change_owner_root $bash_profile_file"
change_owner_root "$bash_profile_file" 644 "false" ". $profile_file"
exit_if_operation_failed "$?"

if [ -f "$home_dir/.bash_logout" ]; then
  echo_info "Removing .bash_logout..."
  rm "$home_dir/.bash_logout"
fi

echo ""
echo_success "You can add command for $username with below command:"
echo "sudo ln -s /bin/*command* $bin_dir/"
