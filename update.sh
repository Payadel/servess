clear_git() {
  git_dir=$1

  echo "Clear git source..."

  if ! sudo rm -r "$git_dir"; then
    echo "Operation failed." >&2
    exit $?
  fi
  echo "done."
}

name=Servess
cliName=servess
install_dir="/opt"
install_servess_dir="$install_dir/$cliName"
bin_path="/usr/local/bin/servess"
currentDir=$(pwd)
libs_dir="$install_dir/shell-libs"
shells_dir="$install_dir/shells"
git_dir="$currentDir/$name"

if [ -d "$name" ]; then
  printf "Directory %s is exist. do you want replace it? (y/n): " "$name"
  read -r delete
  if [ "$delete" = "y" ] || [ "$delete" = "Y" ]; then
    sudo rm -r "$name"
  else
    random_string=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 13)
    git_dir="$currentDir/$random_string"
  fi
fi

git_shells_dir="$git_dir/Shells"
git_servess_dir="$git_dir/$name"

echo "Cloning..."

if ! git clone https://github.com/HamidMolareza/$name.git "$git_dir"; then
  echo "Operation failed." >&2
  exit $?
fi

echo "done."
echo "======================================================================="

echo "Installing shell libs..."
if [ -d "$libs_dir" ]; then
  sudo rm -r "$libs_dir"
fi

if ! sudo mkdir -p "$libs_dir" && sudo cp -r "$git_shells_dir"/libs/* "$libs_dir/" && sudo chmod -R 750 "$libs_dir"; then
  echo "Operation failed." >&2
  clear_git "$git_dir"

  exit $?
fi

if [ -d "$shells_dir" ]; then
  sudo rm -r "$shells_dir"
fi

if ! sudo mkdir -p "$shells_dir" && sudo cp "$git_shells_dir/installer.sh" "$shells_dir/" && sudo chmod -R 750 "$shells_dir/"; then
  echo "Operation failed." >&2
  clear_git "$git_dir"

  exit $?
fi

echo "done."
echo "======================================================================="

echo "Installing $cliName..."
echo "Building project..."

if [ -d "$install_servess_dir" ]; then
  sudo rm -r "$install_servess_dir"
fi

if ! sudo mkdir -p "$install_servess_dir" && sudo chmod 750 "$install_servess_dir"; then
  echo "Operation failed." >&2
  clear_git "$git_dir"

  exit $?
fi

publish_file="$git_servess_dir/publish.sh"

if ! sudo chmod 750 "$publish_file" && ($publish_file "$install_servess_dir" "$git_servess_dir/$name"); then
  echo "Operation failed." >&2
  clear_git "$git_dir"

  exit $?
fi

echo "done."

echo "Adding execute access..."

if ! sudo chmod 750 "$install_servess_dir/$cliName"; then
  echo "Operation failed." >&2
  clear_git "$git_dir"

  exit $?
fi
echo "done."

echo "Creating ln to $bin_path..."
if [ -f "$bin_path" ]; then
  sudo rm "$bin_path"
fi

if ! sudo ln -s "$install_servess_dir/$cliName" "$bin_path"; then
  echo "Operation failed." >&2
  clear_git "$git_dir"

  exit $?
fi
echo "done."

clear_git "$git_dir"
