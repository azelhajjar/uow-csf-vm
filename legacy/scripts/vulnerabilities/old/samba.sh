#!/bin/bash

# Add Samba port to iptables rules
iptables -A INPUT -p tcp --dport 445 -j ACCEPT

# Install Samba package
apt-get install -y samba

# Copy smb.conf configuration file
cp ../files/samba/smb.conf /etc/samba/smb.conf

# Copy passdb.tdb file
cp ../files/samba/passdb.tdb /var/lib/samba/private/passdb.tdb
chmod 0600 /var/lib/samba/private/passdb.tdb

# Restart Samba service
systemctl enable smbd
systemctl restart smbd
