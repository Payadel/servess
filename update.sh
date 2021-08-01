exit_if_operation_failed() {
  local code="$1"
  local message="$2"

  if [ "$code" != "0" ]; then
    if [ -n "$message" ]; then
      echo -e "$message" >&2
    else
      echo "Operation failed with code $code."
    fi
    exit "$code"
  fi
}

clear_git() {
  git_dir="$1"

  echo "Clear git source..."
  sudo rm -r "$git_dir"
  exit_if_operation_failed $?
}

name=Servess
cliName=servess
install_dir="/opt"
install_servess_dir="$install_dir/$cliName"
bin_path="/usr/local/bin/servess"
libs_dir="$install_dir/shell-libs"
git_dir="$name"

if [ -d "$name" ]; then
  printf "Directory %s is exist. do you want replace it? (y/n): " "$name"
  read -r delete
  if [ "$delete" = "y" ] || [ "$delete" = "Y" ]; then
    sudo rm -r "$name"
  else
    random_string=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13)
    git_dir="$random_string"
  fi
fi

git_shells_dir="$git_dir/Shells"
git_servess_dir="$git_dir/$name"

echo "Cloning..."
git clone https://github.com/HamidMolareza/$name.git "$git_dir"
exit_if_operation_failed $?

echo "Installing shell libs..."
if [ -d "$libs_dir" ]; then
  sudo rm -r "$libs_dir"
fi

sudo mkdir -p "$libs_dir" && sudo cp -r "$git_shells_dir"/libs/* "$libs_dir/" && sudo chmod -R 750 "$libs_dir"
exit_if_operation_failed $?

sudo cp "$git_shells_dir/installer.sh" "$git_shells_dir"/libs/ && sudo chmod -R 750 "$git_shells_dir"/libs/installer.sh
exit_if_operation_failed $?

echo "Installing $cliName..."

echo "Building project..."
if [ -d "$install_servess_dir" ]; then
  sudo rm -r "$install_servess_dir"
fi

sudo mkdir -p "$install_servess_dir" && sudo chmod 750 "$install_servess_dir"
exit_if_operation_failed $?

publish_file="$git_servess_dir/publish.sh"

sudo chmod 750 "$publish_file" && ($publish_file "$install_servess_dir" "$git_servess_dir")
exit_if_operation_failed $?

echo "Adding execute access..."
sudo chmod 750 "$install_servess_dir/$cliName"
exit_if_operation_failed $?

echo "Creating ln to $bin_path..."
if [ -f "$bin_path" ]; then
  sudo rm "$bin_path"
fi

if [ -f "$bin_path" ]; then
    rm "$bin_path"
fi
sudo ln -s "$install_servess_dir/$cliName" "$bin_path"
exit_if_operation_failed $?

clear_git "$git_dir"
