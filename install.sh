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
sudo apt install -y git-all
if [ $? != 0 ]; then
    echo "Operation failed."
    exit 1
fi

echo "done."
echo "======================================================================="

echo "Clonning project..."

git clone https://github.com/HamidMolareza/$name.git
if [ $? != 0 ]; then
    echo "Operation failed."
    exit 1
fi

cd "$name"
echo "done."
echo "======================================================================="

echo "Installing shell libs..."
cd "Shells"
sudo mkdir -p "$libs_dir"
sudo cp libs/* "$libs_dir/"
sudo chmod -R 750 "$libs_dir/"

mkdir -p "$shells_dir"
sudo cp installer.sh "$shells_dir/"
sudo chmod -R 750 "$shells_dir/"

echo "done."
echo "======================================================================="
#================================================================================

#Servess
echo "Install tools..."

echo "Install dotnet..."
sudo "$libs_dir/dotnet5-install.sh"
if [ $? != 0 ]; then
    echo "Operation failed."
    exit 1
fi

echo "done."
echo "======================================================================="

echo "Installing $cliName..."
echo "Building project..."
cd "$currentDir/$name/$name"

sudo mkdir -p "$install_servess_dir"
sudo chmod 750 "$install_servess_dir"
sudo chmod 750 ./publish.sh && (./publish.sh "$install_servess_dir")
if [ $? != 0 ]; then
    echo "Operation failed."
    exit 1
fi

echo "done."

echo "Adds execute access..."
cd $install_servess_dir && sudo chmod 750 "$cliName"
echo "done."

echo "Adds file to bin dir..."
sudo ln -s "$install_servess_dir/$cliName" "$bin_path"
echo "done."

echo "Clear git source..."
cd $currentDir && sudo rm -r "$name/"
echo "done."
echo "======================================================================="
