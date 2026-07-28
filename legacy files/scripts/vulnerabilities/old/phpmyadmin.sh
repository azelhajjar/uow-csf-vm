#!/bin/bash
# Download and extract phpMyAdmin
wget -c -t 3 --no-check-certificate -O /tmp/phpMyAdmin-3.5.8-all-languages.tar.gz https://files.phpmyadmin.net/phpMyAdmin/3.5.8/phpMyAdmin-3.5.8-all-languages.tar.gz
echo "a129d4f03901c047799f634b122734ab687b48975563c87adbf5dea679676e11  /tmp/phpMyAdmin-3.5.8-all-languages.tar.gz" | shasum -a 256 --check --status
tar xvfz /tmp/phpMyAdmin-3.5.8-all-languages.tar.gz -C /var/www/html
mv /var/www/html/phpMyAdmin-3.5.8-all-languages /var/www/html/phpmyadmin

# Copy phpMyAdmin configuration file
cp /scripts/files/phpmyadminconf.inc.php /var/www/html/phpmyadmin/config.inc.php

# Restart Apache
systemctl restart apache2
