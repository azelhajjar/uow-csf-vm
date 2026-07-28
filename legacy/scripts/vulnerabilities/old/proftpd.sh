#!/bin/bash


PROFTPD_IP_RENEWER_SCRIPT="/opt/proftpd/proftpd_ip_renewer.rb"
HOSTS_RENEWER_SCRIPT="/opt/proftpd/hosts_renewer.rb"

# Install iptables rule
iptables -A INPUT -p tcp --dport 21 -j ACCEPT


# Download and extract ProFTPD
wget -c -t 3 --no-check-certificate -O /tmp/proftpd-1.3.5.tar.gz ftp://ftp.proftpd.org/distrib/source/proftpd-1.3.5.tar.gz
tar xvzf "/tmp/proftpd-1.3.5.tar.gz" -C "/tmp/"

# Compile and install ProFTPD
cd "/tmp/proftpd-1.3.5"
./configure --prefix="/opt/proftpd" --with-modules=mod_copy && make && make install

# Add hostname to /etc/hosts
echo "${HOSTNAME} ${IPADDRESS}" >> /etc/hosts

# Copy init script
cp ../files/proftpd/proftpd /etc/init.d/proftpd
chmod 760 /etc/init.d/proftpd
sed -i -e 's/\r//g' /etc/init.d/proftpd

# Copy IP renewer script
cp ../files/proftpd/proftpd_ip_renewer.rb "${PROFTPD_IP_RENEWER_SCRIPT}"
chmod 744 "${PROFTPD_IP_RENEWER_SCRIPT}"

# Copy hosts renewer script
cp ../files/proftpd/hosts_renewer.rb "${HOSTS_RENEWER_SCRIPT}"
chmod 744 "${HOSTS_RENEWER_SCRIPT}"

# Copy and configure init scripts for IP and hosts renewer
cp ../files/proftpd/proftpd_ip_renewer.conf /etc/init/proftpd_ip_renewer.conf
cp ../files/proftpd/hosts_renewer.conf /etc/init/hosts_renewer.conf
chmod 0644 /etc/init/proftpd_ip_renewer.conf
chmod 0644 /etc/init/hosts_renewer.conf

# Start ProFTPD and its renewer services
service proftpd start
service proftpd_ip_renewer start
service hosts_renewer start
