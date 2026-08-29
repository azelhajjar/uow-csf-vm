#!/bin/bash
# setup-base.sh
# Base provisioning for Wirless Security module - Dependices for Ubunttu 
# Author: Dr Ayman El Hajjar

echo " Starting base setup for Raspberry Pi AP unit"

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing wireless/network tools..."
sudo apt install -y linux-headers-$(uname -r)
sudo apt install -y hostapd net-tools isc-dhcp-client dnsmasq lsof iptables iproute2 iw
sudo apt install -y dkms git build-essential libelf-dev
sudo apt install -y libssl-dev libnl-3-dev libnl-genl-3-dev pkg-config git wget

echo "[i] Checking hostapd version..."
if hostapd -v 2>/dev/null | grep -q "hostapd v2.9"; then
  echo "[✓] hostapd v2.9 already installed."
else
  echo "[i] Installing hostapd v2.9 (required for WEP support)..."
  sudo systemctl stop hostapd 2>/dev/null || true
  sudo apt remove -y hostapd --purge || true

  cd /usr/src
  sudo rm -rf hostapd-2.9 hostapd-2.9.tar.gz
  sudo wget -q https://w1.fi/releases/hostapd-2.9.tar.gz
  sudo tar xzf hostapd-2.9.tar.gz
  cd hostapd-2.9/hostapd

  echo "[i] Building hostapd v2.9..."
  sudo make -j"$(nproc)"
  echo "[i] Installing hostapd v2.9..."
  sudo mv /usr/sbin/hostapd /usr/sbin/hostapd.bak 2>/dev/null || true
  sudo install -m 0755 hostapd /usr/sbin/hostapd

  echo "hostapd hold" | sudo dpkg --set-selections
  echo "[✓] hostapd v2.9 installed and held."
fi

echo "Installing needed tools..."
sudo apt install -y nano rfkill curl unzip

echo "[i] Disabling systemd-networkd (to avoid DHCP races with dhcpcd)…"
sudo systemctl stop systemd-networkd 2>/dev/null || true
sudo systemctl disable systemd-networkd 2>/dev/null || true
sudo systemctl mask systemd-networkd 2>/dev/null || true

echo "[i] Removing dhclient to prevent double DHCP leases on wlan0…"
sudo apt purge -y isc-dhcp-client || true

echo "[i] Ensuring dhcpcd ignores AP adapter (lab-wlan)…"
if ! grep -q '^denyinterfaces lab-wlan' /etc/dhcpcd.conf; then
  echo 'denyinterfaces lab-wlan' | sudo tee -a /etc/dhcpcd.conf >/dev/null
fi
sudo systemctl restart dhcpcd || true

if [ ! -f /etc/udev/rules.d/72-lab-wlan.rules ]; then
  echo "[i] Adding udev rule to pin Alfa as lab-wlan…"
  sudo tee /etc/udev/rules.d/72-lab-wlan.rules >/dev/null <<'EOF'
SUBSYSTEM=="net", ACTION=="add", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="8812", NAME="lab-wlan"
EOF
  sudo udevadm control --reload
  sudo udevadm trigger
fi

echo " Disabling default hostapd/dnsmasq..."
sudo systemctl disable --now hostapd.service || echo "[i] hostapd not found"
sudo systemctl disable --now dnsmasq.service || echo "[i] dnsmasq not found"

echo " Enabling SSH access..."
sudo systemctl enable ssh
sudo systemctl start ssh

echo "[i] Stopping systemd-resolved to free port 53 for dnsmasq..."
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

echo "[i] Replacing resolv.conf with static DNS..."
sudo rm -f /etc/resolv.conf
echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null

echo "[i] Cleaning old Idle AP entries from /etc/dnsmasq.conf..."
sudo cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
sudo sed -i '/^address=\/6CSEF005W-AP\//d' /etc/dnsmasq.conf
sudo sed -i '/^interface=wlan0/d' /etc/dnsmasq.conf
sudo sed -i '/^dhcp-range=192.168.140.10/d' /etc/dnsmasq.conf
sudo sed -i '/^dhcp-option=6,192.168.140.1/d' /etc/dnsmasq.conf

echo "[i] Adding hostname override to dnsmasq..."
echo "address=/6CSEF005W-AP/192.168.140.1" | sudo tee -a /etc/dnsmasq.conf > /dev/null
echo "[i] Setting Pi as DNS server for DHCP clients..."
{
  echo "interface=lab-wlan"
  echo "dhcp-range=192.168.140.10,192.168.140.50,255.255.255.0,24h"
  echo "domain-needed"
  echo "bogus-priv"
  echo "no-resolv"
  echo "server=8.8.8.8"
  echo "dhcp-option=6,192.168.140.1"
} | sudo tee -a /etc/dnsmasq.conf > /dev/null

echo " Creating systemd service to enforce regulatory domain for Wi-Fi adapters..."
sudo tee /etc/systemd/system/set-regdom.service > /dev/null <<EOF
[Unit]
Description=Set regulatory domain to GB for Wi-Fi
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iw reg set GB
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable set-regdom.service

sudo rm -f /etc/udev/rules.d/98-wlan-regdom.rules || true

NEW_HOSTNAME="6CSEF005W-AP"
echo " Setting hostname to $NEW_HOSTNAME..."
sudo hostnamectl set-hostname "$NEW_HOSTNAME"
sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$NEW_HOSTNAME/" /etc/hosts

echo "[i] Disabling cloud-init completely..."
sudo touch /etc/cloud/cloud-init.disabled
sudo systemctl disable cloud-init.service cloud-init-local.service cloud-config.service cloud-final.service
sudo rm -rf /etc/cloud/ /var/lib/cloud/

SOURCE_SCRIPT="/home/labadmin/6CSEF005W-PRV/configs/setup-idle-ap.sh"
TARGET_SCRIPT="/usr/local/bin/setup-idle-ap.sh"

if [[ -f "$SOURCE_SCRIPT" ]]; then
  echo " Installing Idle AP script to $TARGET_SCRIPT..."
  sudo cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
  sudo chmod +x "$TARGET_SCRIPT"
else
  echo " ERROR: Idle AP script not found at $SOURCE_SCRIPT"
  exit 1
fi

sudo sed -i '/# Generated by NetworkManager/d' /etc/resolv.conf
echo "# University DNS records" | sudo tee -a /etc/resolv.conf > /dev/null
echo "nameserver 161.74.92.25" | sudo tee -a /etc/resolv.conf > /dev/null
echo "nameserver 161.74.92.50" | sudo tee -a /etc/resolv.conf > /dev/null
echo "# Google DNS records" | sudo tee -a /etc/resolv.conf > /dev/null
echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf > /dev/null

SERVICE_FILE="/etc/systemd/system/idle-ap.service"
echo " Creating systemd service to auto-start Idle AP..."
sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Launch Idle Wireless Access Point at Boot
After=multi-user.target network.target systemd-udev-settle.service
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/bin/sleep 20
ExecStart=/usr/local/bin/setup-idle-ap.sh

[Install]
WantedBy=multi-user.target
EOF

echo " Reloading systemd and enabling + starting idle-ap.service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable idle-ap.service
sudo systemctl start idle-ap.service

echo "[*] Installing service to disable kernel message spam on boot..."
bash configs/disable-kernel-spam.sh

if [[ ! -f /etc/systemd/network/00-wlan0-managed.link ]]; then
  echo "[i] Enforcing udev override to ensure wlan0 is managed..."
  sudo tee /etc/systemd/network/00-wlan0-managed.link > /dev/null <<EOF
[Match]
Name=wlan0

[Link]
Unmanaged=no
EOF
  sudo udevadm control --reload
  sudo udevadm trigger
fi

echo "[i] Configuring wpa_supplicant for default lectern Wi-Fi..."
sudo tee /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=GB

network={
    ssid="lectern"
    psk="6csef005w"
    key_mgmt=WPA-PSK
    priority=10
}
EOF

sudo pkill wpa_supplicant
sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf

echo "[i] Wi-Fi configuration for lectern completed. It will connect automatically after reboot."

echo "[i] Creating systemd service to silence kernel spam from wireless drivers..."
sudo tee /etc/systemd/system/disable-kernel-spam.service > /dev/null <<EOF
[Unit]
Description=Silence noisy kernel messages from wireless drivers
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c '/bin/dmesg -n 1'

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable disable-kernel-spam.service
sudo systemctl start disable-kernel-spam.service

echo "[i] Kernel message spam silencing enabled."

echo "Setup complete. Rebooting..."
sudo reboot
