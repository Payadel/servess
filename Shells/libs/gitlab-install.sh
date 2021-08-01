if [ ! -f /opt/shell-libs/selectEditor.sh ]; then
  echo "Can not find library files." >&2
  exit 1
fi
. /opt/shell-libs/selectEditor.sh

editor=($getEditor "$1")

gitlab_setting_file=/etc/gitlab/gitlab.rb
gitlab_ssl_dir=/etc/gitlab/ssl
install_status_file=~/gitlab_install_status

log() {
  echo "$1"
  echo "$1" >>$install_status_file
}

if [ -f "$install_status_file" ]; then
  rm $install_status_file
fi

log "Update & Install necessary dependencies..."

sudo apt-get update
sudo apt-get install -y curl openssh-server ca-certificates tzdata perl

log "Done."
echo "========================================================================"
echo "========================================================================"
echo "========================================================================"

log "Install..."

curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
echo "Gitlab domain (like https://gitlab.example.com): "
read -r domain
sudo EXTERNAL_URL="$domain" apt-get install gitlab-ce

log "Done."
echo "========================================================================"
echo "========================================================================"
echo "========================================================================"

log "Config SSL..."

echo "SSL cert file: "
read -r cert
echo ""

echo "Create directory in $gitlab_ssl_dir"
sudo mkdir -p $gitlab_ssl_dir
sudo chmod 755 $gitlab_ssl_dir
echo ""

echo "Gitlab domain without http (like gitlab.example.com): "
read -r pureDomain
echo "Copy $cert to $gitlab_ssl_dir/$pureDomain.crt"
sudo cp "$cert" $gitlab_ssl_dir/"$pureDomain".crt
echo ""

echo "SSL private file: "
read -r private
echo "Copy $private to $gitlab_ssl_dir/$pureDomain.key"
sudo cp "$private" $gitlab_ssl_dir/"$pureDomain".key
echo ""

echo "Adds nginx['ssl_certificate'] = '$gitlab_ssl_dir/$pureDomain.crt' to $gitlab_setting_file"
echo "nginx['ssl_certificate'] = '$gitlab_ssl_dir/$pureDomain.crt'" >>$gitlab_setting_file

echo "nginx['ssl_certificate_key'] = '$gitlab_ssl_dir/$pureDomain.key' to $gitlab_setting_file"
echo "nginx['ssl_certificate_key'] = '$gitlab_ssl_dir/$pureDomain.key'" >>$gitlab_setting_file

echo "letsencrypt['enable'] = false to $gitlab_setting_file"
echo "letsencrypt['enable'] = false" >>$gitlab_setting_file

log "Done."
echo "========================================================================"
echo "========================================================================"
echo "========================================================================"

sudo $editor $gitlab_setting_file

log "Reconfigure..."
sudo gitlab-ctl reconfigure
log "Done."

# /etc/letsencrypt/live/
