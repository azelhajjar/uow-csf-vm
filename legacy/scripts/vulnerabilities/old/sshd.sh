#!/bin/bash
echo -e "\e[32m The begining of ssh setup file \e[0m"

# Copy sshd_config file
sudo cp ../files/sshd_config /etc/ssh/sshd_config
sudo chmod 0644 /etc/ssh/sshd_config

#this is temporary
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Restart SSH service
sudo service ssh restart
