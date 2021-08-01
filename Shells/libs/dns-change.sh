if [ ! -f /opt/shell-libs/selectEditor.sh ]; then
  echo "Can not find library files."
  exit 1
fi

. /opt/shell-libs/selectEditor.sh

editor=("$getEditor" "$1")

sudo "$editor" /etc/netplan/01-netcfg.yaml
sudo netplan apply
systemd-resolve --status | grep 'DNS Servers' -A2
