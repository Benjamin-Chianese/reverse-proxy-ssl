#!/bin/bash
echo -e '\033[36;1;4mLancer :\033[0m'
echo '1) Installer les logiciels'
echo '2) Ajouts Reverse Proxy + SSL/TLS'
echo '3) Suppression Reverse Proxy + SSL/TLS'


read -p 'Choix : ' choix


### Choix ###
if [ $choix == 1 ]
then

echo -e "\033[31m## Mise à jour ##\033[0m" 
sudo apt update
sudo apt upgrade -y
echo ""

echo -e "\033[31m## Installation Nginx ##\033[0m" 
sudo apt install nginx -y
echo ""

echo -e "\033[31m## Installation Certbot ##\033[0m" 
sudo apt install certbot -y
echo ""

echo -e "\033[31m## Creation dossier letsencrypt ##\033[0m" 
sudo mkdir -p /var/www/letsencrypt
sudo chmod 0755 /etc/letsencrypt/
echo ""

echo -e "\033[31m## Creation fichier letsencrypt ##\033[0m" 
sudo touch  /etc/nginx/snippets/letsencrypt
echo "location ^~ /.well-known/acme-challenge/ {" >> /etc/nginx/snippets/letsencrypt
echo 'default_type "text/plain";' >> /etc/nginx/snippets/letsencrypt
echo "root         /var/www/letsencrypt;" >> /etc/nginx/snippets/letsencrypt
echo "}" >> /etc/nginx/snippets/letsencrypt
echo ""

echo -e "\033[31m## Mise en place du cron de renouvellement ##\033[0m"
echo "42 23 * * 1 /usr/bin/certbot renew >> /var/log/le-renew.log" >> /etc/crontab 
echo ""

echo -e "\033[31m## Génération cert ssl ##\033[0m"
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096
sudo chmod 600 /etc/ssl/certs/dhparam.pem
###if choix ###        
fi 

if [ $choix == 2 ]
then

read -p 'Nom Application (sonarr) : ' app
read -p 'Adresse Ip (LAN) : ' ip
read -p 'Port (443) : ' port
read -p 'Domaine : (plop.domain.com) : ' domaine
read -p 'Mail : ' mail
echo ""

echo -e "\033[31m## Creation fichier $app ##\033[0m"
if [ -f /etc/nginx/sites-enabled/"$app".conf ]
then 
sudo rm /etc/nginx/sites-enabled/"$app".conf
fi

sudo touch /etc/nginx/sites-available/"$app".conf
echo "server {" >> /etc/nginx/sites-available/"$app".conf 
echo "     listen         80;" >> /etc/nginx/sites-available/"$app".conf 
echo "     server_name    $domaine;" >> /etc/nginx/sites-available/"$app".conf 
echo "" >> /etc/nginx/sites-available/"$app".conf
echo "      location / {" >> /etc/nginx/sites-available/"$app".conf 
echo "         proxy_pass http://$ip:$port;" >> /etc/nginx/sites-available/"$app".conf 
echo "         include    proxy_params;" >> /etc/nginx/sites-available/"$app".conf 
echo "      }" >> /etc/nginx/sites-available/"$app".conf
echo "      include        /etc/nginx/snippets/letsencrypt;" >> /etc/nginx/sites-available/"$app".conf 
echo "" >> /etc/nginx/sites-available/"$app".conf
echo "}" >> /etc/nginx/sites-available/"$app".conf 

echo -e "\033[31m## Mise en service temporaire en HTTP ##\033[0m"
sudo ln -s /etc/nginx/sites-available/"$app".conf /etc/nginx/sites-enabled/"$app".conf
echo ""

echo -e "\033[31m## Redemarrage Nginx ##\033[0m"
sudo systemctl reload nginx.service
echo ""

echo -e "\033[31m## Creation cert $domaine ##\033[0m"
echo ""
sudo certbot certonly --webroot -w /var/www/letsencrypt --agree-tos --no-eff-email --email "$mail" -d "$domaine" --rsa-key-size 4096

echo ""
sudo rm /etc/nginx/sites-enabled/"$app".conf

echo -e "\033[31m## Modification fichier $app ##\033[0m"
echo ""
sudo touch /etc/nginx/sites-available/"$app".conf

echo "server {" >> /etc/nginx/sites-available/"$app".conf 
echo "     listen         80;" >> /etc/nginx/sites-available/"$app".conf 
echo "     server_name    $domaine;" >> /etc/nginx/sites-available/"$app".conf 
echo '     return                    301 https://$server_name$request_uri;' >> /etc/nginx/sites-available/"$app".conf
echo "}" >> /etc/nginx/sites-available/"$app".conf
echo "" >> /etc/nginx/sites-available/"$app".conf

echo "server {" >> /etc/nginx/sites-available/"$app".conf 
echo "     listen         443 ssl http2;" >> /etc/nginx/sites-available/"$app".conf 
echo "     server_name    $domaine;" >> /etc/nginx/sites-available/"$app".conf 
echo "" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_certificate           /etc/letsencrypt/live/$domaine/fullchain.pem;" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_certificate_key       /etc/letsencrypt/live/$domaine/privkey.pem;" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_trusted_certificate   /etc/letsencrypt/live/$domaine/chain.pem;" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_dhparam               /etc/ssl/certs/dhparam.pem;" >> /etc/nginx/sites-available/"$app".conf
echo "" >> /etc/nginx/sites-available/"$app".conf

echo "     ssl_protocols             TLSv1 TLSv1.1 TLSv1.2;" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_prefer_server_ciphers on;" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_ciphers               'kEECDH+ECDSA+AES128 kEECDH+ECDSA+AES256 kEECDH+AES128 kEECDH+AES256 kEDH+AES128 kEDH+AES256 DES-CBC3-SHA +SHA !aNULL !eNULL !LOW !kECDH !DSS !MD5 !EXP !PSK !SRP !CAMELLIA !SEED';" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_ecdh_curve            secp384r1;" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_session_cache         shared:SSL:1m;" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_session_timeout       1440m;" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_stapling              on;" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_stapling_verify       on;" >> /etc/nginx/sites-available/"$app".conf
echo "     ssl_buffer_size           8k;" >> /etc/nginx/sites-available/"$app".conf
echo '     add_header                Strict-Transport-Security "max-age=63072000";' >> /etc/nginx/sites-available/"$app".conf
echo "" >> /etc/nginx/sites-available/"$app".conf

echo "     location / {" >> /etc/nginx/sites-available/"$app".conf 
echo "        proxy_pass http://$ip:$port;" >> /etc/nginx/sites-available/"$app".conf 
echo "        include    proxy_params;" >> /etc/nginx/sites-available/"$app".conf 
echo "" >> /etc/nginx/sites-available/"$app".conf
echo "     }" >> /etc/nginx/sites-available/"$app".conf
echo "" >> /etc/nginx/sites-available/"$app".conf
echo "     include        /etc/nginx/snippets/letsencrypt;" >> /etc/nginx/sites-available/"$app".conf 
echo "}" >> /etc/nginx/sites-available/"$app".conf 


sudo ln -s /etc/nginx/sites-available/"$app".conf /etc/nginx/sites-enabled/"$app".conf

echo ""
echo -e "\033[31m## Redemarrage Nginx ##\033[0m"
sudo systemctl reload nginx.service
fi 

if [ $choix == 3 ]
then

read -p 'Nom Application (sonarr) : ' app
read -p 'Domaine : (plop.domain.com) : ' domaine
echo ""


echo -e "\033[31m## Suppression fichier $app ##\033[0m"
sudo rm /etc/nginx/sites-enabled/"$app".conf
sudo rm -R /etc/letsencrypt/live/$domaine

echo ""
echo -e "\033[31m## Redemarrage Nginx ##\033[0m"
sudo systemctl reload nginx.service
fi
