### Installation des packages

apt-get install nginx firewalld -y > /dev/null

### Suppression de la page par défaut de nginx

unlink /etc/nginx/sites-enabled/default > /dev/null

cp ./reverse-proxy.conf /etc/nginx/sites-available/reverse-proxy.conf > /dev/null

ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf > /dev/null

### Démarrage et activation au démarrage des packages

systemctl enable nginx > /dev/null

systemctl start nginx > /dev/null

### Config du firewall

firewall-cmd --permanent --add-port=80/tcp > /dev/null
firewall-cmd --permanent --add-port=443/tcp > /dev/null
firewall-cmd --permanent --add-port=22/tcp > /dev/null
firewall-cmd --permanent --zone=public --remove-service dhcpv6 > /dev/null

firewall-cmd --reload > /dev/null

echo "Go to http://ipvm/install/index.php for install projectsend"

echo "Go to http://ipproxy/dashboard.php and start use projectsend"

echo "Excute sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="proxy-ip" accept'"

echo "Excute sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source not address="proxy-ip" drop' for lock all ip except proxy-ip"