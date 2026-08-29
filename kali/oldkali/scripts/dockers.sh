#! /usr/bin/bash

null="> /dev/null 2>&1"
r="\033[1;31m"
b="\033[1;34m"
w="\033[0m"

# Enable Docker service
echo -e "${b}Docker enabled${w}"
sudo systemctl enable docker

# Start Docker service
echo -e "${b}Starting Docker...${w}"
sudo systemctl start docker

sudo groupadd docker


# Add the user 'kali' to the 'docker' group
echo -e "${b}Adding user 'kali' to the docker group...${w}"
sudo usermod -aG docker kali
sudo usermod -aG docker-compose kali
# Reload the group memberships 
echo -e "${b}Check groups for user kali...${w}"
echo -e "${b}$(groups kali)${w}"




# Check if Docker is working correctly
echo -e "${b}Checking Docker version...${w}"
sudo docker --version

# Start and enable Apache2 service
echo -e "${b}Starting and configuring Apache2...${w}"
sudo systemctl enable apache2

sudo systemctl start apache2

sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_balancer
sudo a2enmod lbmethod_byrequests
sudo systemctl restart apache2

# Copy configuration files for Apache2
echo -e "${b}Copying Apache2 site configuration files...${w}"
sudo cp /home/kali/uow-newkali/sites/juiceshop.local.conf /etc/apache2/sites-available/juiceshop.local.conf
sudo cp /home/kali/uow-newkali/sites/webgoat.local.conf /etc/apache2/sites-available/webgoat.local.conf
sudo cp /home/kali/uow-newkali/sites/dvwa.local.conf /etc/apache2/sites-available/dvwa.local.conf
sudo cp /home/kali/uow-newkali/sites/webcheck.local.conf /etc/apache2/sites-available/webcheck.local.conf
sudo cp /home/kali/uow-newkali/sites/mutillidae.local.conf /etc/apache2/sites-available/mutillidae.local.conf

# Enable the Apache2 sites
echo -e "${b}Enabling Apache2 sites...${w}"
sudo a2ensite juiceshop.local.conf
sudo a2ensite webgoat.local.conf
sudo a2ensite dvwa.local.conf
sudo a2ensite webcheck.local.conf
sudo a2ensite mutillidae.local.conf

echo -e "${b}Reloading Apache2...${w}"
sudo systemctl reload apache2

echo -e "${b}Updating /etc/hosts for local DNS entries...${w}"
echo "127.0.0.1 juiceshop.local" | sudo tee -a /etc/hosts > /dev/null
echo "127.0.0.1 webgoat.local" | sudo tee -a /etc/hosts > /dev/null
echo "127.0.0.1 dvwa.local" | sudo tee -a /etc/hosts > /dev/null
echo "127.0.0.1 mutillidae.local" | sudo tee -a /etc/hosts > /dev/null
#pulling docker images
echo -e "${b}Pull all docker images...${w}"
docker pull bkimminich/juice-shop
docker pull webgoat/webgoat
docker pull vulnerables/web-dvwa
docker pull lissy93/web-check


# Pulling Mutillidae from github and changing port to 8085
echo -e "${b}Pulling Mutillidae from GitHub...${w}"
mkdir /opt/mutillidae
git clone https://github.com/webpwnized/mutillidae-docker.git /opt/mutillidae
# Change Mutillidae port to 8085: change 127.0.0.1:80:80 to 127.0.0.1:8085:80
echo "[i] Updating Mutillidae Docker port to 8085..."
if [[ -f "/opt/mutillidae/.build/docker-compose.yml" ]]; then
    sed -i "s|127.0.0.1:80:80|127.0.0.1:8085:80|" /opt/mutillidae/.build/docker-compose.yml
    echo "[✓] Port updated: Mutillidae will now run on http://localhost:8085"
else
    echo "[!] Could not find /opt/mutillidae/.build/docker-compose.yml"
fi
# Set container name and restart policy for Mutillidae
echo "[i] Adding container_name and restart policy to Mutillidae..."

if [[ -f "/opt/mutillidae/.build/docker-compose.yml" ]]; then
    # Remove any existing container_name to avoid duplication
    sed -i '/container_name:/d' /opt/mutillidae/.build/docker-compose.yml

    # Insert after '  www:' line (must be exact match)
    sed -i "/^  www:$/a \ \ \ \ container_name: mutillidae\n\ \ \ \ restart: unless-stopped" /opt/mutillidae/.build/docker-compose.yml

    echo "[✓] container_name and restart policy added to docker-compose.yml"
else
    echo "[!] Could not find /opt/mutillidae/.build/docker-compose.yml"
fi
# Run Docker containers
docker run --name juiceshop -d -p 127.0.0.1:8081:3000  --restart always bkimminich/juice-shop
docker run --name webgoat -d -p 127.0.0.1:8082:8080  -p 127.0.0.1:9090:9090 --restart always -e TZ=Europe/London webgoat/webgoat
docker run --name dvwa -d -p 8083:80 --restart always vulnerables/web-dvwa
docker run --name webcheck -d -p 8084:3000 --restart always lissy93/web-check
docker compose -f /opt/mutillidae/.build/docker-compose.yml up -d






