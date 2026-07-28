
#!/usr/bin/env bash
set -euo pipefail

log() { echo "[+] $*"; }
die() { echo "[-] $*" >&2; exit 1; }

# Require root
[ "$(id -u)" -eq 0 ] || die "Run as root"

WWW="/var/www/html"
APACHE_SVC="apache2"
PHPINI="/etc/php5/apache2/php.ini"

# Try MySQL root with common cases
mysql_try() {
  local q="$1"
  mysql -uroot -e "$q" 2>/dev/null && return 0
  mysql -uroot -proot -e "$q" 2>/dev/null && return 0
  mysql -uroot -pmsfadmin -e "$q" 2>/dev/null && return 0
  return 1
}

log "Check web root"
mkdir -p "$WWW"

log "Tweak PHP for legacy apps"
# Enable include and fopen
sed -i 's/^\s*;\?\s*allow_url_fopen\s*=.*/allow_url_fopen = On/' "$PHPINI" || true
sed -i 's/^\s*;\?\s*allow_url_include\s*=.*/allow_url_include = On/' "$PHPINI" || true
# Show errors (lab use)
sed -i 's/^\s*;\?\s*display_errors\s*=.*/display_errors = On/' "$PHPINI" || true

log "Reload Apache"
service "$APACHE_SVC" reload || systemctl reload "$APACHE_SVC" || true

log "Create DBs and users"
mysql_try "CREATE DATABASE IF NOT EXISTS dvwa;" || die "MySQL root password unknown. Edit mysql_try."
mysql_try "CREATE DATABASE IF NOT EXISTS bwapp;"
mysql_try "CREATE DATABASE IF NOT EXISTS nowasp;"
mysql_try "CREATE USER IF NOT EXISTS 'dvwa'@'localhost' IDENTIFIED BY 'dvwa';"
mysql_try "CREATE USER IF NOT EXISTS 'bee'@'localhost' IDENTIFIED BY 'bug';"
mysql_try "CREATE USER IF NOT EXISTS 'nowasp'@'localhost' IDENTIFIED BY 'nowasp';"
mysql_try "GRANT ALL ON dvwa.* TO 'dvwa'@'localhost';"
mysql_try "GRANT ALL ON bwapp.* TO 'bee'@'localhost';"
mysql_try "GRANT ALL ON nowasp.* TO 'nowasp'@'localhost';"
mysql_try "FLUSH PRIVILEGES;"

log "Install DVWA"
mkdir -p "$WWW/dvwa"
cd "$WWW/dvwa"
curl -fsSL -o dvwa.zip https://github.com/digininja/DVWA/archive/refs/heads/master.zip
unzip -q -o dvwa.zip
rm -f dvwa.zip
shopt -s nullglob
for d in DVWA-*; do mv "$d"/* . && rmdir "$d"; done
shopt -u nullglob
cp -n config/config.inc.php.dist config/config.inc.php
sed -i "s/\('db_user']\).*/\1 = 'dvwa';/; s/\('db_password']\).*/\1 = 'dvwa';/; s/\('db_database']\).*/\1 = 'dvwa';/" config/config.inc.php

log "Install bWAPP"
cd "$WWW"
mkdir -p "$WWW/bwapp"
cd "$WWW/bwapp"
curl -fsSL -o bwapp.zip https://sourceforge.net/projects/bwapp/files/latest/download
unzip -q -o bwapp.zip
rm -f bwapp.zip
sed -i "s/^\$db_username = .*/\$db_username = 'bee';/; s/^\$db_password = .*/\$db_password = 'bug';/; s/^\$db_database = .*/\$db_database = 'bwapp';/" admin/settings.php || true

log "Install Mutillidae"
cd "$WWW"
mkdir -p "$WWW/mutillidae"
cd "$WWW/mutillidae"
curl -fsSL -o mut.zip https://github.com/webpwnized/mutillidae/archive/refs/heads/master.zip
unzip -q -o mut.zip
rm -f mut.zip
shopt -s nullglob
for d in mutillidae-*; do mv "$d"/mutillidae/* . && rm -rf "$d"; done
shopt -u nullglob
sed -i "s/^\$dbname = .*/\$dbname = 'nowasp';/; s/^\$dbusername = .*/\$dbusername = 'nowasp';/; s/^\$dbpassword = .*/\$dbpassword = 'nowasp';/" includes/database-config.inc || true

log "Apache aliases"
cat >/etc/apache2/conf-available/uow-owasp.conf <<'EOF'
Alias /dvwa /var/www/html/dvwa
Alias /bwapp /var/www/html/bwapp
Alias /mutillidae /var/www/html/mutillidae

<Directory /var/www/html>
  Options Indexes FollowSymLinks
  AllowOverride All
  Require all granted
</Directory>
EOF

a2enmod rewrite >/dev/null 2>&1 || true
a2enconf uow-owasp >/dev/null 2>&1 || true
service "$APACHE_SVC" reload || systemctl reload "$APACHE_SVC" || true

log "Set ownership"
chown -R www-data:www-data "$WWW/dvwa" "$WWW/bwapp" "$WWW/mutillidae" || true

log "Done"
echo
echo "Open:"
echo "  http://<ms3-ip>/dvwa/         then run setup"
echo "  http://<ms3-ip>/bwapp/        then run install"
echo "  http://<ms3-ip>/mutillidae/   then set up DB"
echo
echo "DB creds:"
echo "  dvwa: dvwa/dvwa"
echo "  bwapp: bee/bug"
echo "  nowasp: nowasp/nowasp"
