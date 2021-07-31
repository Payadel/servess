pass_length=30
if [ ! -z "$1" ]; then
    pass_length="$1"
fi

password=$(openssl rand -base64 $pass_length)

if [ -f /opt/shell-libs/colors.sh ]; then
    . /opt/shell-libs/colors.sh
    echo_info "Random password: $password"
else
    echo "Random password: $password"
fi
