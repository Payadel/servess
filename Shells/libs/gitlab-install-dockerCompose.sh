. /opt/shell-libs/selectEditor.sh
if [ $? != 0 ]; then
    echo "Can not find library files." >&2
    exit $?
fi

if [ ! -f /opt/shell-libs/colors.sh ] || [ ! -f /opt/shell-libs/utility.sh ]; then
    echo "Can't find libs." >&2
    echo "Operation failed." >&2
    exit 1
fi
. /opt/shell-libs/colors.sh
. /opt/shell-libs/utility.sh

editor=($getEditor $1)

#========================================================================
#Adds gitlab image
printf "Gitlab image path or press enter (empty) for download image: "
read gitlab_image_path

if [ -z $gitlab_image_path ]; then
    echo_info "Pulling gilab image..."
    docker pull gitlab/gitlab-ce
else
    if [ -f "$gitlab_image_path" ]; then
        echo_info "Importing gilab image..."
        cat $gitlab_image_path | docker import - gitlab/gitlab-ce
    else
        echo -e "$ERROR_COLORIZED: Can not find any file." >&2
        exit $?
    fi
fi

exit_if_operation_failed "$?"

#========================================================================
#Sets gitlab home dir
gitlab_home=/srv/gitlab
printf "Gitlab home dir (default: $gitlab_home): "
read input
if [ ! -z $input ]; then
    gitlab_home=$input
fi
mkdir -p $gitlab_home

exit_if_operation_failed "$?"
export GITLAB_HOME="$gitlab_home"
#========================================================================
#Creates gitlab compose file
http_port=8929
printf "Http port: (default: $http_port): "
read port
if [ ! -z $port ]; then
    http_port=$port
fi

ssh_port=2224
printf "SSH port: (default: $ssh_port): "
read port
if [ ! -z $port ]; then
    ssh_port=$port
fi

compose_dir=/var/docker/gitlab
printf "Docker compose dir: (default: $compose_dir): "
read path
if [ ! -z $path ]; then
    compose_dir=$path
fi

mkdir -p $compose_dir

docker_filename=docker-compose.yml
cd $compose_dir && echo "web:
  image: 'gitlab/gitlab-ce:latest'
  restart: always
  ports:
    - '$http_port:80'
    - '$ssh_port:22'
  volumes:
    - '$GITLAB_HOME/config:/etc/gitlab'
    - '$GITLAB_HOME/logs:/var/log/gitlab'
    - '$GITLAB_HOME/data:/var/opt/gitlab'" >>$docker_filename

exit_if_operation_failed "$?"

cd $compose_dir && $editor $docker_filename
#========================================================================
#Run gitlab compose file
echo_info "Run gitlab compose file..."

cd $compose_dir && docker-compose up -d

exit_if_operation_failed "$?"

echo "Done."
#========================================================================
#Config nginx
printf "Server name (like gitlab.example.com): "
read server_name

nginx_dir=/etc/nginx
config_file="$nginx_dir/sites-available/$server_name"

printf "Use ssl (y/n)? (default: y): "
read use_ssl

if [ -z $use_ssl ] || [ $use_ssl == "y" ] || [ $use_ssl == "Y" ]; then
    printf "SSL fullChain file path: "
    read fullchain

    if [ ! -f $fullChain ]; then
        echo -e "$ERROR_COLORIZED: Can not find ant file." >&2
        exit 1
    fi

    printf "SSL privkey file path: "
    read privkey

    if [ ! -f $privkey ]; then
        echo -e "$ERROR_COLORIZED: Can not find ant file." >&2
        exit 1
    fi

    echo "server {
    listen 443 ssl;
    listen [::]:443 ssl;
    ssl_certificate $fullchain;
    ssl_certificate_key $privkey;

   server_name $server_name;

    location / {
        proxy_pass http://localhost:$http_port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}

server {
    if (\$host = $server_name) {
        return 301 https://\$host$request_uri;
    }

    listen 80;
    listen [::]:80;

    server_name $server_name;

    return 404;
}" >>$config_file

else
    echo "server {
    listen 80;
    listen [::]:80;

   server_name $server_name;

    location / {
        proxy_pass http://localhost:$http_port;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}" >>$config_file

fi
exit_if_operation_failed "$?"

$editor $config_file

sudo ln -s $config_file "$nginx_dir/sites-enabled/"
sudo nginx -t

exit_if_operation_failed "$?"

sudo systemctl restart nginx
