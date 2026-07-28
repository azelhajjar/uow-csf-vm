#!/bin/bash

# create weak database
mysql -u root -psploitme -e "CREATE DATABASE IF NOT EXISTS leaked;"

# create weak table
mysql -u root -psploitme -e "CREATE TABLE IF NOT EXISTS leaked.users (id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(50), password VARCHAR(50));"

# insert predictable credentials
mysql -u root -psploitme -e "INSERT INTO leaked.users (username, password) VALUES ('admin', 'admin123'), ('user', 'password'), ('test', '123456');"

# create world-readable dump directory
mkdir -p /var/lib/mysql-leaks
chmod 777 /var/lib/mysql-leaks

# dump database with world-readable permissions
mysqldump -u root -psploitme leaked > /var/lib/mysql-leaks/leaked.sql
chmod 666 /var/lib/mysql-leaks/leaked.sql

# create symlink to sensitive file
ln -sf /etc/shadow /var/lib/mysql-leaks/shadow-link

# restart service
sudo systemctl restart mariadb