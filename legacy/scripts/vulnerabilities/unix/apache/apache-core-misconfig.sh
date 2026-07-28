#!/bin/bash
set -e

# 1. Enable directory listing
sed -i 's/Options FollowSymLinks/Options Indexes FollowSymLinks/' /etc/apache2/apache2.conf

# 2. World-writable web root
chmod -R 777 /var/www/html

# 3. Expose Apache version + modules
sed -i 's/ServerTokens Prod/ServerTokens Full/' /etc/apache2/conf-available/security.conf
sed -i 's/ServerSignature Off/ServerSignature On/' /etc/apache2/conf-available/security.conf

# 4. Enable .htaccess overrides everywhere
sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# 5. Enable CGI execution in web root
a2enmod cgi
sed -i 's/Options Indexes FollowSymLinks/Options Indexes FollowSymLinks ExecCGI/' /etc/apache2/apache2.conf

# 6.  Enable old, unsafe modules
a2enmod autoindex
a2enmod status

# 7. Expose version + modules via a public file
echo "Apache Version:" > /var/www/html/version.txt
apache2ctl -v >> /var/www/html/version.txt
echo "Apache Modules:" >> /var/www/html/version.txt
apache2ctl -M >> /var/www/html/version.txt

#8. Publicly expose /server-status
cat << 'EOF' > /etc/apache2/conf-available/server-status.conf
<Location /server-status>
    SetHandler server-status
    Require all granted
</Location>
EOF

a2enconf server-status

# 9. Enable directory listing recursively
cat << 'EOF' > /etc/apache2/conf-available/dirlisting.conf
<Directory /var/www/html>
    Options Indexes FollowSymLinks ExecCGI
    AllowOverride All
    Require all granted
</Directory>
EOF

a2enconf dirlisting

#10. Add a misconfigured VirtualHos
cat << 'EOF' > /etc/apache2/sites-available/insecure.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html
    ServerName insecure.local

    <Directory /var/www/html>
        Options Indexes FollowSymLinks ExecCGI
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /dev/null
    CustomLog /dev/null combined
</VirtualHost>
EOF

a2ensite insecure.conf

# 11. Allow execution of scripts everywhere
sed -i 's/Options Indexes FollowSymLinks ExecCGI/Options All/' /etc/apache2/apache2.conf

#12. Disable security headers
echo "Header unset X-Frame-Options" >> /etc/apache2/conf-available/security.conf
echo "Header unset X-Content-Type-Options" >> /etc/apache2/conf-available/security.conf
echo "Header unset X-XSS-Protection" >> /etc/apache2/conf-available/security.conf

a2enmod headers

# 13. Restart Apache
systemctl reload apache2
systemctl restart apache2