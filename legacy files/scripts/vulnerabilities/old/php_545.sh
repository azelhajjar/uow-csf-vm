#!/bin/bash

# Fix freetype error
mkdir -pv /usr/include/freetype2/freetype
sudo ln -sf /usr/include/freetype2/freetype.h /usr/include/freetype2/freetype/freetype.h

# Download PHP 5.4.5 tarball
wget -O /tmp/php-5.4.5.tar.gz https://museum.php.net/php5/php-5.4.5.tar.gz

# Download libxml29_compat patch
wget -O /tmp/libxml29_compat.patch https://mail.gnome.org/archives/xml/2012-August/txtbgxGXAvz4N.txt

# Extract PHP tarball
tar xvzf /tmp/php-5.4.5.tar.gz -C /tmp/
cd /tmp/php-5.4.5

# Patch PHP with libxml29_compat
patch -p0 -b < /tmp/libxml29_compat.patch

# Compile and install PHP
./configure --with-apxs2=/usr/bin/apxs --with-mysqli --enable-embedded-mysqli --with-gd --with-mcrypt --enable-mbstring --with-pdo-mysql
make
sudo make install



# Copy PHP configuration files
sudo cp /scripts/files/apache/php5.conf /etc/apache2/mods-available/php5.conf
sudo cp /scripts/files/apache/php5.load /etc/apache2/mods-available/php5.load
# Enable PHP modules
cd /etc/apache2/mods-enabled
sudo a2enmod php5
sudo a2dismod mpm_event
sudo a2enmod mpm_prefork

# Restart Apache
sudo systemctl restart apache2
