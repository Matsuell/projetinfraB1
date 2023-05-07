#!/bin/bash

#On récupère la date
date=`date +"%y%m%d%H%M%S"`

#On définit le nom du fichier
filename=files-backup_$date.zip

#Archivez le dossier
cd /home/mat 
apt install zip > /dev/null
zip -r $filename /usr/share/nginx/projectsend > /dev/null

echo "Zip folder available /home/mat/$filename"
