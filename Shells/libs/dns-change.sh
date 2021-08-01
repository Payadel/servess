sudo nano /etc/netplan/01-netcfg.yaml
sudo netplan apply
systemd-resolve --status | grep 'DNS Servers' -A2
