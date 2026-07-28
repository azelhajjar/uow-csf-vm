#!/bin/bash
set -e

PHPINI="/etc/php/8.2/apache2/php.ini"

sed -i 's/display_errors = Off/display_errors = On/' "$PHPINI"
sed -i 's/log_errors = On/log_errors = Off/' "$PHPINI"
sed -i 's/;allow_url_fopen = On/allow_url_fopen = On/' "$PHPINI"
sed -i 's/;allow_url_include = Off/allow_url_include = On/' "$PHPINI"
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 512M/' "$PHPINI"
sed -i 's/post_max_size = .*/post_max_size = 512M/' "$PHPINI"
sed -i 's/file_uploads = Off/file_uploads = On/' "$PHPINI"

mkdir -p /var/www/html/uploads
chmod -R 777 /var/www/html/uploads

systemctl restart apache2