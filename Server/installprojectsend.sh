### Installation des tous les packages nécessaires

apt install nginx mariadb-server mariadb-client php7.4 php7.4-fpm php7.4-mysql php-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline php7.4-mbstring php7.4-xml php7.4-gd php7.4-curl unzip -y > /dev/null

## Démarrage et activation au démarrage des packages
systemctl enable nginx > /dev/null
systemctl enable php7.4-fpm > /dev/null
systemctl enable mariadb > /dev/null
systemctl start nginx > /dev/null
systemctl start mariadb > /dev/null
systemctl start php7.4-fpm > /dev/null

## Téléchargement et installation de projectsend
wget -O projectsend.zip https://www.projectsend.org/download/614/ > /dev/null

mkdir -p /usr/share/nginx/projectsend/ > /dev/null

unzip projectsend.zip -d /usr/share/nginx/projectsend/ > /dev/null
cp ./confg.php /usr/share/nginx/projectsend/includes/sys.config.php > /dev/null
chown www-data:www-data /usr/share/nginx/projectsend/ -R > /dev/null

cp ./projectsend.conf /etc/nginx/conf.d/projectsend.conf > /dev/null

systemctl restart nginx > /dev/null

apt install firewalld imagemagick php-imagick php7.4-common php7.4-mysql php7.4-fpm php7.4-gd php7.4-json php7.4-curl  php7.4-zip php7.4-xml php7.4-mbstring php7.4-bz2 php7.4-intl php7.4-bcmath php7.4-gmp -y > /dev/null

systemctl enable firewalld > /dev/null

systemctl start firewalld > /dev/null

##Config du firewall
firewall-cmd --permanent --add-port=80/tcp > /dev/null
firewall-cmd --permanent --add-port=443/tcp > /dev/null
firewall-cmd --permanent --add-port=22/tcp > /dev/null
firewall-cmd --permanent --zone=public --remove-service dhcpv6 > /dev/null

firewall-cmd --reload > /dev/null


echo "Execute mysql_secure_installation for create user go to see doc"
