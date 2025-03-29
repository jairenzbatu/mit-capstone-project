#!/bin/bash

# Database credentials
DB_HOST="mydb.cjwouu6wcu2s.ap-southeast-1.rds.amazonaws.com"
DB_NAME="snipeit"
DB_USER="dbuser"
DB_PASS="dbpassword"

# Backup directory
BACKUP_DIR="/opt/db_backup_export"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Get the current date in YYYY-MM-DD format
date_stamp=$(date +"%Y-%m-%d")

# Output file
DUMP_FILE="$BACKUP_DIR/snipe-database-$date_stamp.sql"
ZIP_FILE="$BACKUP_DIR/snipe-database-$date_stamp.zip"

# Create MySQL dump
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$DUMP_FILE"

# Compress the dump file into a zip
zip "$ZIP_FILE" "$DUMP_FILE"

# Remove the original SQL dump file after compression
rm "$DUMP_FILE"

echo "Database backup completed: $ZIP_FILE"

# Sync backup folder to AWS S3
aws s3 sync "$BACKUP_DIR/" s3://jairenz-snipe-seed/database-dump/

echo "Backup folder synced to S3: s3://jairenz-snipe-seed/database-dump/"
