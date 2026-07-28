#!/bin/bash

# Add iptables rule for CUPS
iptables -A INPUT -p tcp --dport 631 -j ACCEPT

# Install CUPS package
apt-get install -y cups

# Copy CUPS configuration file
cp ../files/cupsd.conf /etc/cups/cupsd.conf
chmod 0644 /etc/cups/cupsd.conf

# Restart CUPS service
systemctl enable cups
systemctl restart cups
