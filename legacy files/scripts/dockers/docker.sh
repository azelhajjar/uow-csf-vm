#!/bin/bash

# Install Docker
apt-get update
apt-get install -y docker.io docker-compose

# Start Docker service
systemctl start docker

# Add user(s) to the docker group
groupadd docker
usermod -aG docker uow-vuln
usermod -aG docker vagrant
# Add additional users as needed

# Restart Docker service to apply changes
systemctl restart docker
