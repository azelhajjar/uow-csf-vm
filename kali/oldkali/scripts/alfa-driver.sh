#!/bin/bash
# alfa-driver.sh
# Installs RTL8812AU driver for Alfa AWUS036ACH on Kali Linux
# Author: Dr Ayman El Hajjar

set -e

# Handle optional argument
SKIP_REBOOT=0
if [[ "$1" == "--noreboot" ]]; then
  SKIP_REBOOT=1
fi

echo "[i] Installing RTL8812AU driver for Alfa adapter..."

sudo apt update
sudo apt install -y dkms git build-essential libelf-dev linux-headers-amd64

if [ ! -d "/opt/rtl8812au" ]; then
  git clone https://github.com/aircrack-ng/rtl8812au.git /tmp/rtl8812au
  sudo mv /tmp/rtl8812au /opt/rtl8812au
fi

cd /opt/rtl8812au
sudo make
sudo make install

echo "[✓] RTL8812AU driver installed successfully."

if [[ $SKIP_REBOOT -eq 0 ]]; then
  echo "[i] Rebooting to apply driver..."
  sudo reboot
else
  echo "[i] Reboot skipped (invoked with --noreboot)"
fi
