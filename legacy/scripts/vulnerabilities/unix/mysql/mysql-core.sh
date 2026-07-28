#!/bin/bash

# set root password for MariaDB (Debian Bookworm)
mysql -u root -psploitme -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'sploitme';"

# allow remote connections
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

# restart service
sudo systemctl restart mariadb
