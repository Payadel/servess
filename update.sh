clear_git() {
    git_dir=$1

    echo "Clear git source..."
    sudo rm -r "$git_dir"
    if [ $? != 0 ]; then
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
    printf "Directory $name is exist. do you want replace it? (y/n): "
    read delete
    if [ "$delete" = "y" ] || [ "$delete" = "Y" ]; then
        sudo rm "$name"
    fi
fi

git clone https://github.com/HamidMolareza/$name.git
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    exit $?
fi

cd "$name"
echo "done."
echo "======================================================================="

echo "Installing shell libs..."
cd "Shells"
if [ -d "$libs_dir" ]; then
    sudo rm -r "$libs_dir"
fi
sudo mkdir -p "$libs_dir" && sudo cp libs/* "$libs_dir/" && sudo chmod -R 750 "$libs_dir/"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    clear_git "$git_dir"

    exit $?
fi

if [ -d "$shells_dir" ]; then
    sudo rm -r "$shells_dir"
fi
sudo mkdir -p "$shells_dir" && sudo cp installer.sh "$shells_dir/" && sudo chmod -R 750 "$shells_dir/"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    clear_git "$git_dir"

    exit $?
fi

echo "done."
echo "======================================================================="

echo "Installing $cliName..."
echo "Building project..."
cd "$git_dir/$name"

if [ -d "$install_servess_dir" ]; then
    sudo rm -r "$install_servess_dir"
fi
sudo mkdir -p "$install_servess_dir" && sudo chmod 750 "$install_servess_dir"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    clear_git "$git_dir"

    exit $?
fi

sudo chmod 750 ./publish.sh && (./publish.sh "$install_servess_dir")
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    clear_git "$git_dir"

    exit $?
fi

echo "done."

echo "Adds execute access..."
cd $install_servess_dir && sudo chmod 750 "$cliName"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    clear_git "$git_dir"

    exit $?
fi
echo "done."

echo "Adds file to bin dir..."
if [ -f "$bin_path" ]; then
    sudo rm "$bin_path"
fi
sudo ln -s "$install_servess_dir/$cliName" "$bin_path"
if [ $? != 0 ]; then
    echo "Operation failed." >&2
    clear_git "$git_dir"

    exit $?
fi
echo "done."

clear_git "$git_dir"
