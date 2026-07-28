#!/bin/bash

# create remote root account
mysql -u root -psploitme -e "CREATE OR REPLACE USER 'root'@'%' IDENTIFIED BY 'sploitme';"

# allow remote root login
mysql -u root -psploitme -e "UPDATE mysql.global_priv SET priv = JSON_SET(priv, '$.host', '%') WHERE user='root' AND host='localhost';"

# create anonymous user with full privileges
mysql -u root -psploitme -e "CREATE OR REPLACE USER ''@'%' IDENTIFIED BY '';"
mysql -u root -psploitme -e "GRANT ALL PRIVILEGES ON *.* TO ''@'%' WITH GRANT OPTION;"

# enable FILE privilege for remote root
mysql -u root -psploitme -e "GRANT FILE ON *.* TO 'root'@'%';"

# flush privileges
mysql -u root -psploitme -e "FLUSH PRIVILEGES;"

# restart service
sudo systemctl restart mariadb