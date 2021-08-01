name=Servess
cliName=servess
install_dir="/opt"
install_servess_dir="$install_dir/$cliName"
bin_path="/usr/local/bin/servess"
currentDir=$(pwd)
libs_dir="$install_dir/shell-libs"
shells_dir="$install_dir/shells"

echo "Install tools..."

echo "Install git..."

if ! sudo apt install -y git-all; then
  echo "Operation failed." >&2
  exit $?
fi

echo "done."
echo "======================================================================="

echo "Cloning project..."

if ! git clone https://github.com/HamidMolareza/$name.git; then
  echo "Operation failed." >&2
  exit $?
fi

cd "$name" || exit
echo "done."
echo "======================================================================="

echo "Installing shell libs..."
cd "Shells" || exit

if ! sudo mkdir -p "$libs_dir" && sudo cp libs/* "$libs_dir/" && sudo chmod -R 750 "$libs_dir/"; then
  echo "Operation failed." >&2
  exit $?
fi

if ! mkdir -p "$shells_dir" && sudo cp installer.sh "$shells_dir/" && sudo chmod -R 750 "$shells_dir/"; then
  echo "Operation failed." >&2
  exit $?
fi

echo "done."
echo "======================================================================="
#================================================================================

#Servess
echo "Install tools..."

echo "Install dotnet..."

if ! sudo "$libs_dir/dotnet5-install.sh"; then
  echo "Operation failed." >&2
  exit $?
fi

echo "done."
echo "======================================================================="

echo "Installing $cliName..."
echo "Building project..."
cd "$currentDir/$name/$name" || exit

if ! sudo mkdir -p "$install_servess_dir" && sudo chmod 750 "$install_servess_dir"; then
  echo "Operation failed." >&2
  exit $?
fi

if ! sudo chmod 750 ./publish.sh && (./publish.sh "$install_servess_dir"); then
  echo "Operation failed." >&2
  exit $?
fi

echo "done."

echo "Adds execute access..."

if ! cd $install_servess_dir && sudo chmod 750 "$cliName"; then
  echo "Operation failed." >&2
  exit $?
fi
echo "done."

echo "Adds file to bin dir..."

if ! sudo ln -s "$install_servess_dir/$cliName" "$bin_path"; then
  echo "Operation failed." >&2
  exit $?
fi
echo "done."

echo "Clear git source..."

if ! cd "$currentDir" && sudo rm -r "$name/"; then
  echo "Operation failed." >&2
  exit $?
fi
echo "done."
echo "======================================================================="
