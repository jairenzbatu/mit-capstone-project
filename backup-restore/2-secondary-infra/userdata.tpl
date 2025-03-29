#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Variables
BUCKET="s3://jairenz-snipe-seed"
DB_BUCKET="s3://mit-backup-restore-database"
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

# List S3 files, filter for .zip, sort by date, and get the latest file
echo "listing database dumps"
aws s3 ls "$DB_BUCKET/database-dump/"
LATEST_FILE=$(aws s3 ls "$DB_BUCKET/database-dump/" | awk '{print $4}' | grep '\.zip$' | sort -r | head -n 1)

# Check if a file was found
if [[ -z "$LATEST_FILE" ]]; then
    echo "No .zip files found in $DB_BUCKET/database-dump"
elif [[ -n "$LATEST_FILE" ]]; then
    # Download the latest file
    echo "Downloading latest backup: $LATEST_FILE"
    aws s3 cp $DB_BUCKET/database-dump/$LATEST_FILE "$DABATABSE_DIR/"
    echo "Backup saved to $DABATABSE_DIR/$LATEST_FILE"
fi

echo "Setting up app and database variables"
RDS_HOST=${db_host}
RDS_ROOT_USER=${db_root_user}
RDS_ROOT_PASS=${db_root_pass}
APP_URL=${app_subdomain}
DB_NAME="snipeit"

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
# RESTORE DATABASE DUMP
# --------------------------------------
# Extract the backup file
unzip -o "$DABATABSE_DIR/$LATEST_FILE" -d "$DABATABSE_DIR/"

# Find the SQL file in the extracted contents
SQL_FILE=$(find "$DABATABSE_DIR" -type f -name "*.sql" | head -n 1)

if [[ -z "$SQL_FILE" ]]; then
    echo "No SQL file found in the extracted backup"
fi

# Restore database
echo "Restoring database from $SQL_FILE..."
mysql -h "$RDS_HOST" -u "$RDS_ROOT_USER" -p"$RDS_ROOT_PASS" "$DB_NAME" < "$SQL_FILE"
echo "Database restore completed successfully."

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

# --------------------------------------
# DATABASE MANUAL BACKUPS
# --------------------------------------
DB_BACKUP_SCRIPT_DIR="/opt/bnr-scripts"
mkdir -p $DB_BACKUP_SCRIPT_DIR

# copy script from s3 bucket
aws s3 cp $BUCKET/scripts/backup-database.sh $DB_BACKUP_SCRIPT_DIR/

# replace dbhost placeholder with DB Host URL
sed -i "s/DB_HOST_HERE/$RDS_HOST/g" $DB_BACKUP_SCRIPT_DIR/backup-database.sh

# make the script executable
chmod +x $DB_BACKUP_SCRIPT_DIR/backup-database.sh

# run the script every 5 mins to backup the database via cron
# Define the cron job
CRON_JOB="*/5 * * * * $DB_BACKUP_SCRIPT_DIR/backup-database.sh"

# Check if the cron job already exists
(crontab -l 2>/dev/null | grep -Fq "backup-database.sh") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

echo "Cron job added to run every 5 minutes."