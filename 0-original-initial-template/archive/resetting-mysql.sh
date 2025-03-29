mysql -h mydb.ctss440wygde.us-west-2.rds.amazonaws.com -udbuser -pdbpassword -e "CREATE DATABASE snipeit;"
mysql -h mydb.ctss440wygde.us-west-2.rds.amazonaws.com -udbuser -pdbpassword -e "CREATE USER 'snipeit-user'@'%' IDENTIFIED BY '"$RDS_ROOT_PASS"';"
mysql -h mydb.ctss440wygde.us-west-2.rds.amazonaws.com -udbuser -pdbpassword -e "GRANT ALL ON snipeit.* TO 'snipeit-user'@'%';"




mysql -h mydb.ctss440wygde.us-west-2.rds.amazonaws.com -udbuser -pdbpassword -e "REVOKE ALL PRIVILEGES ON snipeit.* FROM 'snipeit-user'@'%';"
mysql -h mydb.ctss440wygde.us-west-2.rds.amazonaws.com -udbuser -pdbpassword -e "DROP USER 'snipeit-user'@'%';"
mysql -h mydb.ctss440wygde.us-west-2.rds.amazonaws.com -udbuser -pdbpassword -e "DROP DATABASE snipeit;"



DROP USER 'phpmyadmin'@'localhost';