#!/bin/bash

# Cookbook:: metasploitable
# Recipe:: drupal
#
# Copyright:: 2017, Rapid7, All Rights Reserved.

# Include other scripts (assuming they are in the same directory)
source ./apache.sh
source ./mysql.sh
source ./php_545.sh

DRUPAL_VERSION="7.56"  # Set the Drupal version
DRUPAL_TAR="drupal-${DRUPAL_VERSION}.tar.gz"
CODER_TAR="coder-7.x-2.5.tar.gz"
FILES_PATH="./files/drupal"  # Adjust the path as needed
INSTALL_DIR="/var/www/html/drupal"  # Adjust the install directory as needed
SITES_DIR="${INSTALL_DIR}/sites"
DEFAULT_SITE_DIR="${SITES_DIR}/default"
ALL_SITE_DIR="${SITES_DIR}/all"

DRUPAL_DOWNLOAD_URL="https://ftp.drupal.org/files/projects"  # Set the Drupal download URL

# Download Drupal and coder tarballs
wget -O "/tmp/${DRUPAL_TAR}" "${DRUPAL_DOWNLOAD_URL}/${DRUPAL_TAR}"
wget -O "/tmp/${CODER_TAR}" "${DRUPAL_DOWNLOAD_URL}/${CODER_TAR}"

# Create the installation directory
mkdir -p "${INSTALL_DIR}"
chown www-data:www-data "${INSTALL_DIR}"
chmod 0755 "${INSTALL_DIR}"

# Debug logging
echo "Contents of install directory: $(ls -l ${INSTALL_DIR})"

# Untar Drupal if the directory is empty
if [ -z "$(ls -A ${INSTALL_DIR})" ]; then
  tar xvzf "/tmp/${DRUPAL_TAR}" -C "${INSTALL_DIR}" --strip-components 1
fi

# Untar default site
if [ ! -f "${DEFAULT_SITE_DIR}/settings.php" ] || [ ! -d "${DEFAULT_SITE_DIR}/files" ]; then
  tar xvzf "${FILES_PATH}/default_site.tar.gz" -C "${SITES_DIR}"
fi

# Untar coder module
if [ ! -d "${ALL_SITE_DIR}/modules/coder" ]; then
  tar xvzf "/tmp/${CODER_TAR}" -C "${ALL_SITE_DIR}/modules"
fi

# Set permissions
chown -R www-data:www-data "${INSTALL_DIR}"

# Create Drupal database and inject data
if ! mysql -h 127.0.0.1 --user="root" --password="sploitme" --execute="SHOW DATABASES LIKE 'drupal'" | grep -c drupal; then
  mysql -h 127.0.0.1 --user="root" --password="sploitme" --execute="CREATE DATABASE drupal;"
  mysql -h 127.0.0.1 --user="root" --password="sploitme" --execute="GRANT SELECT, INSERT, DELETE, CREATE, DROP, INDEX, ALTER ON drupal.* TO 'root'@'localhost' IDENTIFIED BY 'sploitme';"
  mysql -h 127.0.0.1 --user="root" --password="sploitme" drupal < "${FILES_PATH}/drupal.sql"
fi

# Replace 5_of_hearts.png
cp "${FILES_PATH}/5_of_hearts.png" "/var/www/html/drupal/sites/default/files/styles/large/public/field/image/5_of_hearts.png"
chmod 0777 "/var/www/html/drupal/sites/default/files/styles/large/public/field/image/5_of_hearts.png"

cp "${FILES_PATH}/5_of_hearts.png" "/var/www/html/drupal/sites/default/files/field/image/5_of_hearts.png"
chmod 0777 "/var/www/html/drupal/sites/default/files/field/image/5_of_hearts.png"
