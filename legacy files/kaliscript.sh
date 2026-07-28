#! /usr/bin/bash

null="> /dev/null 2>&1"
g="\033[1;32m"
r="\033[1;31m"
b="\033[1;34m"
w="\033[0m"

#DNS configurations for university
echo "nameserver 161.74.92.25" | sudo tee -a /etc/resolv.conf > /dev/null
echo "nameserver 161.74.92.50" | sudo tee -a /etc/resolv.conf > /dev/null

sudo apt-get update
sudo apt-get -y install docker.io 
sudo systemctl enable docker
sudo gpasswd -a $USER docker

sudo service start apache2
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer
sudo a2enmod lbmethod_byrequests
sudo systemctl restart apache2


# Change keyboard to UK - only apply after a reboot
sudo sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="gb"/' /etc/default/keyboard
sudo systemctl restart keyboard-setup.service


sudo cp sites/juiceshop.local.conf /etc/apache2/sites-available/juiceshop.local.conf
sudo cp sites/webgoat.local.conf /etc/apache2/sites-available/webgoat.local.conf
sudo cp sites/dvwa.local.conf /etc/apache2/sites-available/dvwa.local.conf
sudo cp sites/dvws.local.conf /etc/apache2/sites-available/dvws.local.conf
sudo cp sites/dvws.local.conf /etc/apache2/sites-available/webcheck.local.conf

sudo a2ensite juiceshop.local.conf
sudo a2ensite webgoat.local.conf
sudo a2ensite dvws.local.conf
sudo a2ensite dvwa.local.conf
sudo a2ensite webcheck.local.conf
sudo systemctl reload apache2

#DNS for local dockers
echo "12.0.0.1 juiceshop.local" | sudo tee -a /etc/hosts > /dev/null
echo "12.0.0.1 webgoat.local" | sudo tee -a /etc/hosts > /dev/null
echo "12.0.0.1 dvws.local" | sudo tee -a /etc/hosts > /dev/null
echo "12.0.0.1 juicedvwashop.local" | sudo tee -a /etc/hosts > /dev/null
echo "12.0.0.1 webcheck.local" | sudo tee -a /etc/hosts > /dev/null







docker run --name juiceshop  -d -p 127.0.0.1:8081:3000 bkimminich/juice-shop
docker run --name webgoat -d -p 127.0.0.1:8082:8080  -e TZ=Europe/Amsterdam webgoat/webgoat
docker run --name dvws  -d -p 8083:80 -p 8091:8080 tssoffsec/dvws
docker run --name dvwa  -d -it -p 8084:80 vulnerables/web-dvwa
docker run --name webcheck  -d -p 8086:3000 lissy93/web-check

#dependencies
sudo apt-get install -y   python3-lxml python3-requests python3-email-validator python3-googlesearch

#tools
sudo apt-get -y install osrframework p0f zenmap
sudo apt-get install wget && wget https://raw.githubusercontent.com/termuxhackers-id/SIGIT/main/installkali.sh && sudo bash installkali.sh
wget https://github.com/angryip/ipscan/releases/download/3.9.1/ipscan_3.9.1_amd64.deb && sudo dpkg -i ipscan_3.9.1_amd64.deb


