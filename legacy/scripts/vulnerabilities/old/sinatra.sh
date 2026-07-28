#!/bin/bash

# Add Sinatra port to iptables rules
iptables -A INPUT -p tcp --dport 8181 -j ACCEPT

# Create directories
mkdir -p /opt/sinatra
mkdir -p /var/opt/sinatra
chmod 0777 /opt/sinatra
chmod 0777 /var/opt/sinatra

# Copy Gemfile
cp ../files/sinatra/Gemfile /opt/sinatra/Gemfile
chmod 0777 /opt/sinatra/Gemfile

# Copy server script
cp ../files/sinatra/server /opt/sinatra/server
chmod 0777 /opt/sinatra/server

# Copy init script
cp ../files/sinatra/sinatra.conf /etc/init/sinatra.conf
chmod 0777 /etc/init/sinatra.conf

# Start Sinatra service
initctl start sinatra
