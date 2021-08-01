#Libs
if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
  echo "Can't find libs." >&2
  echo "Operation failed." >&2
  exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

echo_info "Enabling IP V6..."
servess firewall ipv6 -e
show_warning_if_operation_failed "$?"
echo ""

echo_info "Deny incoming and Allow outgoing by default..."
sudo ufw default deny incoming && sudo ufw default allow outgoing
show_warning_if_operation_failed "$?"
echo ""

echo_info "Allow ssh..."
sudo ufw allow ssh
exit_if_operation_failed "$?"
echo ""

echo_info "Allow HTTP and HTTPS ports..."
sudo ufw allow 80/tcp comment 'accept HTTP connections' && sudo ufw allow 443/tcp comment 'accept HTTPS connections'
show_warning_if_operation_failed "$?"
echo ""

echo_info "Restarting firewall..."
sudo ufw disable && sudo ufw enable
show_warning_if_operation_failed "$?"
echo ""

sudo ufw show added
