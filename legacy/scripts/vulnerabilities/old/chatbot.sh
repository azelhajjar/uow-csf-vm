#!/bin/bash

# Include recipes for installing Ruby and Node.js
# Assuming the recipes are defined elsewhere in your script

# Add iptables rules for Chatbot UI and Node.js
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 3000 -j ACCEPT

# Install unzip package
 apt-get install nodejs npm

# Install Node.js dependencies
npm install -g express
npm install -g cors

# Copy Chatbot archive to /tmp
cp ../files/chatbot.zip /tmp

# Unzip Chatbot archive to /opt
unzip /tmp/chatbot.zip -d /opt

# Change ownership of Chatbot directory
chown -R root:root /opt/chatbot

# Set permissions for Chatbot directory
chmod -R 700 /opt/chatbot

# Execute Chatbot installation script
/opt/chatbot/install.sh

# Enable and start Chatbot service
systemctl daemon-reload
systemctl enable chatbot
systemctl start chatbot
