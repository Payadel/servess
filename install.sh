name=Servess
cliName=servess
install_dir="/opt"
install_servess_dir="$install_dir/$cliName"
bin_path="/usr/local/bin/servess"
libs_dir="$install_dir/shell-libs"

echo "Install git..."
if ! sudo apt install -y git-all; then
  code="$?"
  echo "Operation failed." >&2
  exit $code
fi

echo "Cloning project..."
if ! git clone https://github.com/HamidMolareza/$name.git; then
  code="$?"
  echo "Operation failed." >&2
  exit $code
fi

echo "Installing shell libs..."
if ! sudo mkdir -p "$libs_dir" && sudo cp $name/Shells/libs/* "$libs_dir/" && sudo chmod -R 750 "$libs_dir/"; then
  code="$?"
  echo "Operation failed." >&2
  exit $code
fi

if ! sudo cp name/Shells/installer.sh "$libs_dir/" && sudo chmod 750 "$libs_dir/installer.sh"; then
  code="$?"
  echo "Operation failed." >&2
  exit $code
fi

#Servess

echo "Install dotnet..."
if ! sudo "$libs_dir/dotnet5-install.sh"; then
  code="$?"
  echo "Operation failed." >&2
  exit $code
fi

echo "Installing $cliName..."
echo "Building project..."

if ! sudo mkdir -p "$install_servess_dir" && sudo chmod 750 "$install_servess_dir"; then
  code="$?"
  echo "Operation failed." >&2
  exit $code
fi

if ! sudo chmod 750 $name/$name/publish.sh && ($name/$name/publish.sh "$install_servess_dir"); then
  code="$?"
  echo "Operation failed." >&2
  exit $code
fi

echo "Adds execute access..."
if ! cd $install_servess_dir && sudo chmod 750 "$cliName"; then
  code="$?"
  echo "Operation failed." >&2
  exit $code
fi

echo "Adds file to bin dir..."
if ! sudo ln -s "$install_servess_dir/$cliName" "$bin_path"; then
  code="$?"
  echo "Operation failed." >&2
  exit $code
fi

echo "Clear git source..."
if ! sudo rm -r "$name/"; then
  code="$?"
  echo "Operation failed." >&2
  exit $code
fi

echo "done."
