#!/bin/bash

RDS_HOST=$1
RDS_ROOT_USER=$2
RDS_ROOT_PASS=$3

# --------------------------------------
# DOCKER CONFIGURATION
# --------------------------------------
echo "Installing Docker"
# installation
sudo yum install -y docker

# permission and group configuration
sudo usermod -a -G docker ec2-user
id ec2-user
newgrp "docker"

# enable docker service
sudo systemctl enable docker.service
sudo systemctl start docker.service

# --------------------------------------
# MYSQL CLIENT INSTALLATION
# --------------------------------------
echo "Installing MySQL Client"
cd /opt
sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm 
sudo dnf install mysql80-community-release-el9-1.noarch.rpm -y
sudo dnf install mysql-community-server -y
rm -f mysql80-community-release-el9-1.noarch.rpm

# --------------------------------------
# SNIPE DATABASE CONFIGURATION
# --------------------------------------
echo "Creating SnipeIT Database"
mysql -h ${RDS_HOST} -p ${RDS_ROOT_USER} -p ${RDS_ROOT_PASS} -e "CREATE DATABASE snipeit;"
mysql -h ${RDS_HOST} -p ${RDS_ROOT_USER} -p ${RDS_ROOT_PASS} -e "CREATE USER 'snipeit-user'@'%' IDENTIFIED BY ''${RDS_ROOT_PASS}'';"
mysql -h ${RDS_HOST} -p ${RDS_ROOT_USER} -p ${RDS_ROOT_PASS} -e "GRANT ALL ON snipeit.* TO 'snipeit-user'@'%';"

# --------------------------------------
# SNIPE CREATE ENV FILE
# --------------------------------------
echo "Creating SnipeIT Env File"
env_content = "# --------------------------------------------
# REQUIRED: DATABASE SETTINGS
# --------------------------------------------
DB_CONNECTION=mysql
DB_HOST="${RDS_HOST}"
DB_DATABASE=snipeit
DB_USERNAME=snipeit-user
DB_PASSWORD="${RDS_ROOT_PASS}"
DB_PREFIX=snipe
DB_DUMP_PATH='/usr/bin'
DB_CHARSET=utf8mb4
DB_COLLATION=utf8mb4_unicode_ci

# Email Parameters
# - the hostname/IP address of your mailserver
MAIL_PORT_587_TCP_ADDR=smtp.whatever.com
#the port for the mailserver (probably 587, could be another)
MAIL_PORT_587_TCP_PORT=587
# the default from address, and from name for emails
MAIL_ENV_FROM_ADDR=youremail@yourdomain.com
MAIL_ENV_FROM_NAME=Your Full Email Name
# - pick 'tls' for SMTP-over-SSL, 'tcp' for unencrypted
MAIL_ENV_ENCRYPTION=tcp
# SMTP username and password
MAIL_ENV_USERNAME=your_email_username
MAIL_ENV_PASSWORD=your_email_password

# Snipe-IT Settings
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:2sDxFfjJq4GJr4qjTx8EFSAaImBlPEDcUBWVh/HNU3o=
APP_URL=http://snipe.jai.com
APP_TIMEZONE=US/Pacific
APP_LOCALE=en
  
# Docker-specific variables
PHP_UPLOAD_LIMIT=100
"

echo -e "$env_content" > /opt/my_env

# --------------------------------------
# SNIPE DOCKER CONTAINER
# --------------------------------------
echo "Starting Snipe Docker Container"
docker run -d -p 80:80 --name="snipeit" --env-file=/opt/my_env --mount source=snipe-vol,dst=/var/lib/snipeit snipe/snipe-it