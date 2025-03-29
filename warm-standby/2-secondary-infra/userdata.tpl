#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Variables
BUCKET="s3://jairenz-snipe-seed"
DABATABSE_DIR="/opt/db-backup"
APPDATA_DIR="/var/lib/docker/volumes/snipe-vol/_data/"
CRON_DATA="/opt/cron"

# CREATE CRON FOLDER
mkdir -p $CRON_DATA

# CREATE APP FOLDER
mkdir -p $APPDATA_DIR

# CREATE DATABASE DUMP FOLDER
mkdir -p $DABATABSE_DIR

# SYNC DATA FROM S3 TO RESTORE SNIPE
aws s3 sync $BUCKET/application-data/ $APPDATA_DIR

#list the directory
echo "listing data directory"
ls -l $APPDATA_DIR

echo "Setting up variables"
RDS_HOST=${db_host}
RDS_ROOT_USER=${db_root_user}
RDS_ROOT_PASS=${db_root_pass}
APP_URL=${app_subdomain}


# --------------------------------------
# DOCKER CONFIGURATION
# --------------------------------------
echo "Installing Docker"
# installation
sudo yum install -y docker

# permission and group configuration
echo "Updating Permissions"
sudo usermod -a -G docker ec2-user
id ec2-user
newgrp "docker"

# enable docker service
echo "Enabling Docker Service"
sudo systemctl enable docker.service
sudo systemctl start docker.service

# --------------------------------------
# MYSQL CLIENT INSTALLATION
# --------------------------------------
echo "Installing MySQL Client"
sudo dnf install mariadb105-server -y

# --------------------------------------
# SNIPE DATABASE CONFIGURATION
# --------------------------------------
echo "Checking if the database exist already."
# Check if the database exists
if mysql -u $RDS_ROOT_USER -p$RDS_ROOT_PASS -h $RDS_HOST -e "USE snipeit" 2>/dev/null; then
    echo "Database snipeit already exists."
else
    # Create the database
    mysql -u $RDS_ROOT_USER -p$RDS_ROOT_PASS -h $RDS_HOST -e "CREATE DATABASE snipeit;"
    echo "Database snipeit created successfully."
fi

# Check if the user exists
if mysql -u $RDS_ROOT_USER -p$RDS_ROOT_PASS -h $RDS_HOST -e "SELECT User FROM mysql.user WHERE User='snipeit-user'" | grep "snipeit-user" 2>/dev/null; then
    echo "MySQL user snipeit-user already exists."
else
    # Create the user
    mysql -u $RDS_ROOT_USER -p$RDS_ROOT_PASS -h $RDS_HOST -e "CREATE USER 'snipeit-user'@'%' IDENTIFIED BY '$RDS_ROOT_PASS'"
    mysql -u $RDS_ROOT_USER -p$RDS_ROOT_PASS -h $RDS_HOST -e "GRANT ALL ON snipeit.* TO 'snipeit-user'@'%';'"
    echo "MySQL user snipeit-user created successfully."
fi

# --------------------------------------
# SNIPE CREATE ENV FILE
# --------------------------------------
echo "Creating SnipeIT Env File"
env_content="# -------------------------------------------- \n# REQUIRED: DATABASE SETTINGS \n# -------------------------------------------- \nDB_CONNECTION=mysql\nDB_HOST="$RDS_HOST"\nDB_DATABASE=snipeit\nDB_USERNAME=snipeit-user\nDB_PASSWORD="$RDS_ROOT_PASS"\nDB_PREFIX=snipe\nDB_DUMP_PATH='/usr/bin'\nDB_CHARSET=utf8mb4\nDB_COLLATION=utf8mb4_unicode_ci\n\n# Snipe-IT Settings\nAPP_ENV=production\nAPP_DEBUG=false\nAPP_KEY=base64:2sDxFfjJq4GJr4qjTx8EFSAaImBlPEDcUBWVh/HNU3o=\nAPP_URL=https://$APP_URL\nAPP_TIMEZONE=Asia/Manila\nAPP_LOCALE=en\n\n# Docker-specific variables\nPHP_UPLOAD_LIMIT=100\n"

echo -e $env_content > /opt/my_env

# --------------------------------------
# SNIPE DOCKER CONTAINER
# --------------------------------------
echo "Starting Snipe Docker Container"
docker run -d -p 80:80 --name="snipeit" \
--env-file=/opt/my_env \
--mount source=snipe-vol,dst=/var/lib/snipeit \
snipe/snipe-it

docker exec -t snipeit chmod -R 777 /var/www/html/

# --------------------------------------
# APP DATASYNC CRONJOB
# --------------------------------------

# install and enable crontab
sudo dnf install cronie -y
sudo systemctl start crond
sudo systemctl enable crond

# Add the cron job if it doesn't already exist
CRON_JOB="*/5 * * * * aws s3 sync $APPDATA_DIR $BUCKET/application-data/"

# Check if the cron job already exists
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "Crontab entry added to sync S3 data every 5 minutes."