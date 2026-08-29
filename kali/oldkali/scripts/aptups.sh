#!/bin/bash

set -e

r="\033[1;31m"
b="\033[1;34m"
w="\033[0m"

echo -e "${b}Updating package lists...${w}"
sudo apt-get update

echo -e "${b}Installing Docker tools...${w}"
sudo apt-get -y install docker.io
sudo apt-get -y install docker-compose

echo -e "${b}Installing NumLockX...${w}"
sudo apt-get install -y numlockx
