#!/bin/bash

# Install knockd package
apt-get install -y knockd

# Create knockd configuration file
cat <<EOF > /etc/knockd.conf
# Knockd configuration
[options]
        logfile = /var/log/knockd.log

[openSSH]
        sequence    = 7000,8000,9000
        seq_timeout = 5
        command     = /sbin/iptables -I INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
        tcpflags    = syn

[closeSSH]
        sequence    = 9000,8000,7000
        seq_timeout = 5
        command     = /sbin/iptables -D INPUT -s %IP% -p tcp --dport 22 -j ACCEPT
        tcpflags    = syn
EOF

# Set permissions for knockd configuration file
chmod 0600 /etc/knockd.conf

# Copy knockd default configuration file
cp ../files/knockd /etc/default/knockd

# Remove carriage returns from knockd default configuration file
sed -i -e 's/\r//g' /etc/default/knockd

# Add iptables rule to drop incoming traffic on specified port
iptables -I FORWARD 1 -p tcp -m tcp --dport $VULN_PORT -j DROP

# Start knockd service
systemctl enable knockd
systemctl start knockd
