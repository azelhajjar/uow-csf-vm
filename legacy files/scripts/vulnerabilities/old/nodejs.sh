#!/bin/bash

# Add Node.js 4 repository
#if [ ! -f /usr/bin/node ]; then
#    curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
#fi

#wget https://deb.nodesource.com/setup_4.x
#sudo ./setup_4.x

# Install Node.js package
apt-get update
apt-get install -y nodejs --yes
