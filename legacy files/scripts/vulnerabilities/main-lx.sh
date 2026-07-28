#!/bin/bash
apt update
apt install -y sudo curl wget git net-tools unzip tar

#installing services
apt install -y apache2
apt install -y mariadb-server
apt install -y php php-mysql libapache2-mod-php php-cli php-curl php-zip php-xml php-mbstring
apt install -y vsftpd
apt install -y samba


# Enable services
systemctl enable apache2
systemctl enable mariadb
systemctl enable vsftpd
systemctl enable smbd


#starting services
systemctl start apache2
systemctl start mariadb
systemctl start vsftpd
systemctl start smbd

#misconfiging apache
./vulnerabilities/unix/apache/apache-core-misconfig.sh
./vulnerabilities/unix/apache/apache-ssl-misconfig.sh
./vulnerabilities/unix/apache/php-misconfig.sh
./vulnerabilities/unix/apache/logging-misconfig.sh