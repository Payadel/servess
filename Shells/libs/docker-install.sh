sudo apt-get update

sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
if [ $? != 0 ]; then
  echo "Operation failed." >&2
  exit $?
fi

printf "Do you want to login in docker? (y/n): "
read loginToDocker
if [ "$loginToDocker" = "y" ] || [ "$loginToDocker" = "Y" ]; then
  docker login
  sudo docker run hello-world
fi
