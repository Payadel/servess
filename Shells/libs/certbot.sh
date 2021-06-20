sudo apt install certbot python3-certbot-nginx

echo "Domain (like example.com):"
read domain

sudo certbot certonly \
    --agree-tos \
    --manual \
    --preferred-challenges=dns \
    -d *.$domain \
    -d $domain \
    --server https://acme-v02.api.letsencrypt.org/directory
