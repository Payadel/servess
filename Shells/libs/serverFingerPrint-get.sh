echo "Server finger print"
echo "-----------------------------------------------------"
cat /etc/ssh/ssh_host_rsa_key.pub
echo "-----------------------------------------------------"

printf "Please check server finger print and press enter key to continue."
read -r _
