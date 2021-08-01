if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ] || [ ! -f /opt/shell-libs/motd-add.sh ] || [ ! -f /opt/shell-libs/nginx-services-check.sh ] || [ ! -f /opt/shell-libs/apache-remove.sh ]; then
  echo "Can't find libs" >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

/opt/shell-libs/apache-remove.sh

sudo apt update
show_warning_if_operation_failed $?

sudo apt install -y nginx && sudo systemctl enable nginx
exit_if_operation_failed "$?"

printf "Do you want see service checks in system welcome messages? (y/n): "
read -r input
if [ "$input" == "y" ] || [ "$input" == "Y" ]; then
  /opt/shell-libs/motd-add.sh "/opt/shell-libs" "nginx-services-check.sh"
fi
