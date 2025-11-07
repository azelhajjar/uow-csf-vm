#!/bin/bash
set -euo pipefail

# Create directories
sudo mkdir -p /opt/apache-elf/bin /opt/apache-elf/conf /opt/apache-elf/htdocs /opt/apache-elf/logs /opt/apache-elf/modules /opt/apache-elf-extract

# Extract from artifacts
sudo tar -xzf /srv/cav-csf/artifacts/apache_elf_package.tar.gz -C /opt/apache-elf-extract
sudo tar -xzf /srv/cav-csf/artifacts/apache2-modules-i386.tar.gz -C /opt/apache-elf

# Copy binary
sudo cp -f /opt/apache-elf-extract/bin/apache2 /opt/apache-elf/bin/httpd
sudo chmod 755 /opt/apache-elf/bin/httpd

# Fix mime types
sudo mkdir -p /etc/apache2
[ -f /etc/apache2/mime.types ] || sudo ln -sf /etc/mime.types /etc/apache2/mime.types

# Apache configuration
sudo tee /opt/apache-elf/conf/httpd.conf > /dev/null <<'EOF'
ServerRoot "/opt/apache-elf"
Listen 80
ServerName 127.0.0.1

LoadModule mime_module          /opt/apache-elf/modules/mod_mime.so
LoadModule dir_module           /opt/apache-elf/modules/mod_dir.so
LoadModule env_module           /opt/apache-elf/modules/mod_env.so
LoadModule setenvif_module      /opt/apache-elf/modules/mod_setenvif.so
LoadModule alias_module         /opt/apache-elf/modules/mod_alias.so
LoadModule authz_host_module    /opt/apache-elf/modules/mod_authz_host.so
LoadModule auth_basic_module    /opt/apache-elf/modules/mod_auth_basic.so
LoadModule autoindex_module     /opt/apache-elf/modules/mod_autoindex.so

User www-data
Group www-data
PidFile "/opt/apache-elf/logs/httpd.pid"
ErrorLog "/opt/apache-elf/logs/error_log"
CustomLog "/opt/apache-elf/logs/access_log" common

DocumentRoot "/opt/apache-elf/htdocs"
<Directory "/opt/apache-elf/htdocs">
    Options Indexes FollowSymLinks ExecCGI
    AllowOverride None
    Order allow,deny
    Allow from all
</Directory>

DirectoryIndex index.html
EOF

# Default page
echo "<html><body><h1>Apache</h1></body></html>" | sudo tee /opt/apache-elf/htdocs/index.html > /dev/null
sudo chown -R www-data:www-data /opt/apache-elf
sudo chmod -R 755 /opt/apache-elf/htdocs

# Service file
sudo tee /etc/systemd/system/apache-elf.service > /dev/null <<'EOF'
[Unit]
Description=Apache ELF
After=network.target

[Service]
Type=simple
Environment=LD_LIBRARY_PATH=/opt/apache-elf-extract/lib:/opt/apache-elf-extract/lib32:/opt/apache-elf-extract/lib/i386-linux-gnu:/opt/apache-elf-extract/usr/lib/i386-linux-gnu:/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu
ExecStart=/opt/apache-elf/bin/httpd -f /opt/apache-elf/conf/httpd.conf -DFOREGROUND
WorkingDirectory=/opt/apache-elf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now apache-elf.service

sudo rm -f -- "$0"
