. /opt/shell-libs/selectEditor.sh
if [ $? != 0 ]; then
    echo "Can not find library files."
    exit 1
fi

editor=($getEditor $1)

sudo $editor /etc/netplan/01-netcfg.yaml
sudo netplan apply
systemd-resolve --status | grep 'DNS Servers' -A2
