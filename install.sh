#! /bin/bash

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

delete_dir_or_file() {
  local input="$1"

  if [ -d "$input" ]; then
    echo "Directory $input is exist."
    printf "Do you want delete it? (y/n): "
    read -r delete_input
    if [ "$delete_input" = "y" ] || [ "$delete_input" = "Y" ]; then
      rm -r "$input"
    fi
  fi

  if [ -f "$input" ]; then
    echo "File $input is exist."
    printf "Do you want delete it? (y/n): "
    read -r delete_input
    if [ "$delete_input" = "y" ] || [ "$delete_input" = "Y" ]; then
      rm "$input"
    fi
  fi
}

name=Servess
cliName=servess
install_dir="/opt"
install_servess_dir="$install_dir/$cliName"
bin_path="/usr/local/bin/servess"
libs_dir="$install_dir/shell-libs"

echo "Updating..."
sudo apt update

echo "Install git..."
sudo apt install -y git-all
exit_if_operation_failed "$?"

echo "Cloning project..."
delete_dir_or_file "$name"
git clone https://github.com/HamidMolareza/$name.git
exit_if_operation_failed "$?"

echo "Installing shell libs..."
delete_dir_or_file "$libs_dir"
sudo mkdir -p "$libs_dir" && sudo cp $name/Shells/libs/* "$libs_dir/" && sudo chmod -R 750 "$libs_dir/"
exit_if_operation_failed "$?"

sudo cp $name/Shells/installer.sh "$libs_dir/" && sudo chmod 750 "$libs_dir/installer.sh"
exit_if_operation_failed "$?"

#Download Servess app
wget https://github.com/HamidMolareza/Servess/releases/download/latest/release.tar.gz && tar -xvzf release.tar.gz
exit_if_operation_failed "$?"

#Move Servess app
sudo mkdir "$install_servess_dir"
sudo cp -r release/* "$install_servess_dir"
exit_if_operation_failed "$?"

rm release.tar.gz
rm -r release

echo "Adds execute access..."
sudo chmod 750 "$install_servess_dir/$cliName"
exit_if_operation_failed "$?"

echo "Adds file to bin dir..."
delete_dir_or_file "$bin_path"
sudo ln -s "$install_servess_dir/$cliName" "$bin_path"
exit_if_operation_failed "$?"

echo "Clear git source..."
sudo rm -r "$name/"
exit_if_operation_failed "$?"

echo "done."
