#!/bin/bash

r="\033[1;31m"
b="\033[1;34m"
w="\033[0m"

echo -e "${b}Updating package repository database...${w}"
./scripts/aptups.sh

echo -e "${b}Installing Alfa wireless driver...${w}"
./scripts/alfa-driver.sh --noreboot

echo -e "${b}Configuring VM Machine...${w}"
./scripts/configs.sh

echo -e "${b}Installing tools...${w}"
# You may want to call a specific tools.sh here if needed

echo -e "${b}Installing required Docker containers...${w}"
./scripts/dockers.sh

# Copy student ID script for screenshot prompts
cp ./scripts/studentid.sh /home/kali/studentid.sh
chmod +x /home/kali/studentid.sh
sudo chattr +i /home/kali/studentid.sh


# Schedule deletion of this script and other setup files
echo -e "${b}Cleaning up setup files and history...${w}"

# Spawn a background process to wait and delete
(sleep 2 && rm -rf ~/scripts ~/kaliscript.sh ~/.bash_history && \
  sudo rm -rf /root/.bash_history && \
  unset HISTFILE && history -c) &

# Clear history before reboot
history -c
unset HISTFILE

echo -e "${b}Rebooting system now...${w}"
sudo reboot now


# Reboot to apply changes
echo -e "${b}Rebooting the system for changes to take effect...${w}"
sudo reboot now
