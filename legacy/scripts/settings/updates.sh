#!/bin/bash

echo -e "\e[32m The begining of updates.sh \e[0m"

sudo apt-get update --fix-missing
sudo apt-get install -y systemd
sudo apt-get install -y software-properties-common
sudo apt-get install -y unzip
sudo apt-get install -y ruby

# Install required libraries for php
sudo apt-get install -y gcc make build-essential libxml2-dev libcurl4-openssl-dev libpcre3-dev libbz2-dev libjpeg-dev libfreetype6-dev  libmcrypt-dev libmhash-dev freetds-dev libmysqlclient-dev unixodbc-dev libxslt1-dev apache2-dev


# Install MySQL Server
sudo apt-get install -y mysql-server

# Install Git
apt-get install -y git