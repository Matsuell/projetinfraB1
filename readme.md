## Explications et prérequis pour l'installation de cette solution

**Pour installer projectsend protéger par un reverse proxy vous devez posséder 2 machines avec Ubuntu ou Debian installé**

**Cette solution a été réalisée sur une version 20.04 de Ubuntu**

**->Vos 2 machines doivent toutes les 2 posséder une adresse ip afin de pouvoir vous y connecter et un accès internet afin d'installer tous les packages nécessaires**

## Configuration du serveur pour projectSend

**ProjectSend est écrit en langage de programmation PHP. Pour suivre ce tutoriel, vous devez d'abord installer la pile LEMP sur Ubuntu 20.04 . Pour cela:**


```bash
sudo apt install nginx mariadb-server mariadb-client -y
```

### Démarrage des services du serveur:

```bash
sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl start mariadb
sudo systemctl enable mariadb
```


**Vous pouvez vérifier que le service ait bien démarré à l'aide cette commande:**

```bash
sudo systemctl status nginx
sudo systemctl status mariadb
```


### Configuration de mysql pour la gestion des données du service

```bash
sudo mysql_secure_installation

Puis répondez yes (y) à toutes les questions qui vous seront posées afin de créer un mot de passe et de sécuriser mysql

```

### Installation des dépendances de PHP

**Etant donné que projectsend est une application écrite à l'aide de PHP vous devrez afin de pouvoir l'utiliser installer plusieurs dépendances de PHP**

```bash
sudo apt install imagemagick php-imagick php7.4-bz2 php7.4 php7.4-fpm php7.4-mysql php7.4-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline php7.4-mbstring php7.4-xml php7.4-gd php7.4-curl php7.4-intl php7.4-bcmath php7.4-gmp php7.4-zip
```

### Démarrage du service PHP

```bash
sudo systemctl start php7.4-fpm
sudo systemctl enable php7.4-fpm
```

**Vous pouvez vérifier que le service ait bien démarré à l'aide cette commande:**

```bash
sudo systemctl status php7.4-fpm
```

### Installation du service projectsend

**Pour installer le service projectsend vous devez télécharger l'archive contenant tous les fichiers en exécutant une requête sur leur site:**

```bash
wget -O projectsend.zip https://www.projectsend.org/download/614/
```

**Puis afin d'extraire cette archiv vous devez si vous ne l'avez pas déjà installer unzip pour décompresser le dossier:**

```bash
sudo apt install unzip
```

**Créer le dossier qui servira à acceuillir les fichiers contenus dans l'archive:**

```bash
sudo mkdir -p /usr/share/nginx/projectsend/
```

**Décompressez l'archive dans le dossier que vous venez de créer**

```bash
sudo unzip projectsend.zip -d /usr/share/nginx/projectsend/
```

**Vous devez attribuer tous les fichiers à l'utilisateur www-data qui est l'utilisateur par défaut du service nginx à savoir le serveur web**

```bash
sudo chown www-data:www-data /usr/share/nginx/projectsend/ -R
```

**Vous devez par la suite créez une base de données qui servira à stocker tous les utilisateurs lorsque vous utiliserez le site (changez les noms d'utilisateurs et les mots de passes par ceu que vous souhaitez)**

```bash
sudo mysql
create database projectsend;
create user projectsenduser@localhost identified by 'your-password';
grant all privileges on projectsend.* to projectsenduser@localhost;
flush privileges;
exit;
```

**Une fois que la base de données a été créée, il faut indiquer à projectsend quel est le nom de la base à utiliser et où la trouver puis comment s'y connecter, nous allons donc pour cela copier le fichier de configuration par défaut et le configurer comme nous le souhaitons**


```bash
sudo cp /usr/share/nginx/projectsend/includes/sys.config.sample.php /usr/share/nginx/projectsend/includes/sys.config.php
```

```bash
/** Database name */
define('DB_NAME', 'database');

/** Database host (in most cases it's localhost) */
define('DB_HOST', 'localhost');

/** Database username (must be assigned to the database) */
define('DB_USER', 'username');

/** Database password */
define('DB_PASSWORD', 'password');
```

**Les lignes présentes si dessus sont les seules lignes que vous devez modifier en fonction de ce que vous aurez créé précédemment**

**Une fois que vous aurez dit à projectsend comment récupérer la liste de utilisateurs présent vous devez indiquer à nginx comment il doit afficher le service sur une page web**


```bash
sudo nano /etc/nginx/conf.d/projectsend.conf


server {
    listen 80;
    listen [::]:80;
    server_name à remplacer par votre nom de domaine;

    # Add headers to serve security related headers
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Download-Options noopen;
    add_header X-Permitted-Cross-Domain-Policies none;
    add_header Referrer-Policy no-referrer;

    # Path to the root of your installation
    root /usr/share/nginx/projectsend/;
    index index.php index.html;

    access_log /var/log/nginx/projectsend.access;
    error_log /var/log/nginx/projectsend.error;

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location ~ /.well-known/acme-challenge {
      allow all;
    }

    # set max upload size
    client_max_body_size 512M;
    fastcgi_buffers 64 4K;

    # Disable gzip to avoid the removal of the ETag header
    gzip off;

    # Uncomment if your server is build with the ngx_pagespeed module
    # This module is currently not supported.
    #pagespeed off;

    error_page 403 /core/templates/403.php;
    error_page 404 /core/templates/404.php;

    location / {
      try_files $uri $uri/ /index.php;
    }

    location ~ \.php$ {
       include fastcgi_params;
       fastcgi_split_path_info ^(.+\.php)(/.*)$;
       try_files $fastcgi_script_name =404;
       fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
       fastcgi_param PATH_INFO $fastcgi_path_info;
       #Avoid sending the security headers twice
       fastcgi_param modHeadersAvailable true;
       fastcgi_param front_controller_active true;
       fastcgi_pass unix:/run/php/php7.4-fpm.sock;
       fastcgi_intercept_errors on;
       fastcgi_request_buffering off;
    }

   location ~* \.(?:svg|gif|png|html|ttf|woff|ico|jpg|jpeg)$ {
        try_files $uri /index.php$uri$is_args$args;
        # Optional: Don't log access to other assets
        access_log off;
   }
}
```

## Redémarrage de nginx pour prendre en compte toutes les modifications

```bash
sudo systemctl reload nginx
```

**Si vous utiliser un pare-feu afin de protéger votre machine vous devez autorisé le trafic à passer par le port 80**

**Avec iptable:**
```bash
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
```

**Avec firewalld:**

```bash
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload
```

**Si vous souhaitez utiliser le https vous devez autoriser le port 443 et installer d'autres dépendances:**
```bash
sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx --agree-tos --redirect --hsts --staple-ocsp --email you@example.com -d projectsend.example.com
```

*Remplacez you@example.com par votre adresse mail et projectsend.example.com par le bom de votre site*

**Avec firewalld:**

```bash
sudo firewall-cmd --add-port=443/tcp --permanent
sudo firewall-cmd --reload
```

**Si vous utilisez hhtps rendez-vous la page https://projectsend.example.com/install/index.php pour terminer l'installation**

**Sinon rendez-vous sur http://projectsend.example.com/install/index.php**

**Vous devrez sru cette page retranscrire les informations précedemment crées pour terminer l'installation**

https://www.hostinger.com/tutorials/how-to-set-up-nginx-reverse-proxy/

# Installation d'un reverse proxy 

**Un reverse proxy vous permet dans un premier temps de meilleures performances sur votre site et vous permet aussi en cas d'attaque par un pirate de s'il arrive à faire tomber votre machine vous n'aurez "que" le reverse proxy à resetup plutôt que de devoir reconfiguré toute votre installation cela permet donc un peu plus de sécurité**

### Installation de nginx 

**Pour mettre en place ce reverse proxy nous allons installaer nginx qui est un moyen simple de mettre en place ce type d'installation**

```bash
sudo apt-get install nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

**Ensuite nous devons désactiver la page par défaut de nginx qui ne nous interresse pas**

```bash
sudo unlink /etc/nginx/sites-enabled/default
```

### Configuration du reverse proxy:

**Une fois que la page par défaut a été désactivée nous devons écrire un fichier qui s'appellera reverse-proxy.conf qui se trouvera dans le dossier /etc/nginx/sites-available**

```bash
sudo nano /etc/nginx/sites/available/reverse-proxy.conf
```

**Collez y ce contenu en remplaçant la ligne server_name par l'adresse de votre server**

```bash
server {
    server_name A remplacer par le nom de domaine ou l'ip de votre proxy;
    listen 80;
    location / {
        proxy_pass http://ipduserver;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**Activez ensuite cette nouvelle configuration**

```bash
sudo ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf
```

**Redémarrez nginx pour appliquer les modifications**

```bash
sudo systemctl restart nginx
```

**Si vous utiliser un pare feu vous devez ouvrir les ports comme pour le serveur**

**Avec iptable:**
```bash
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
```

**Avec firewalld:**

```bash
sudo firewall-cmd --add-port=80/tcp --permanent
sudo firewall-cmd --reload
```

**Rendez-vous encuite sur votre navigateur http://ipproxy/dashboard.php pour profiter du service via le reverse proxy**

*Lors de votre navigation sur projectsend vous remarquerez que vous pointez vers votre serveur alors que vous naviguez via votre proxy, rendez-vous dans la section options, options générales puis tout en bas "emplacement du système"*

*Pour empecher tous les trafic de passer par votre server vous devez bloquer toutes les adresses sauf celle du proxy sur votre serveur via ces 2 commandes:*

```bash
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source not address="proxy-ip" drop'
sudo firewall-cmd --permanent --zone=public --add-rich-rule='rule family="ipv4" source address="proxy-ip" accept'
sudo firewall-cmd --reload
```


# Système de backup

**Vous pouvez aussi vous équipez en cas d'attaque sur votre site à l'aide d'une restauration, d'une sauvegarde effectuée tout les x temps ce qui vous permettra de pouvoir restaurer l'activité de votre site en cas de casse**

### A l'aide d'un script

**Pour cela vous devrez créé un dossier partagé ou non avec une machine spécifiquement prévue pour les sauvegardes**

```bash
sudo mkdir /backup
```

**Créez ensuite le script pour les sauvegardes**

```bash
sudo nano /backup/backup.sh
```

**et collez y le contenu suivant**

```bash
#!/bin/bash

#On récupère la date
date=`date +"%y%m%d%H%M%S"`

#On définit le nom du fichier
filename=files-backup_$date.zip

#Archivez le dossier
apt install zip > /dev/null
zip -r $filename /usr/share/nginx/projectsend > /dev/null

echo "Zip folder available /home/mat/$filename"

```

*Donnez ensuite la permission d'exécuter ce script*

```bash
sudo chmod +x /backup/backup.sh
```

**Vous pouvez très bien automatiser l'execution de ce script en le transformant en service à l'aide d'un timer**

**Pour cela modifiez le fichier backup.service**

```bash
sudo nano /etc/systemd/system/backup.service
```

**Collez y le contenu suivant**

```bash
[Unit]
Description=Save files for projectsend



[Service]
Type=oneshot
ExecStart=/backup/backup.sh
User=backup

```

**Créeez ensuite un user spécific pour le script que nous appelerons dans l'exemple backup**

```bash
sudo useradd -m -d /backup/ -s /usr/sbin/nologin backup
```

### Timer pour automatiser la sauvegarde

```bash
sudo nano /etc/systemd/system/backup.timer
```

**Collez y le contenu suivant**

```bash
[Unit]
Description=Run service Backup

[Timer]
OnCalendar=*-*-* 01:00:00

[Install]
WantedBy=timers.target
```


**Dans l'exemple précédent nous exécutons le service backup tous les jours à 01:00:00 vous pouvez mettre ce que vous désirez**

### Démarrage du timer

```bash
sudo systemctl daemon-reload
sudo systemctl start backup.timer
sudo systemctl enable backup.timer
```

**Et voilà vous venez d'automatiser la sauvegarde de votre système**