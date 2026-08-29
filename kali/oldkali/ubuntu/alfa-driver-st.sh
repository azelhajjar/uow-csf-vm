#!/bin/bash
# alfa-driver-unified.sh
# Install RTL8812AU driver for Alfa AWUS036ACH on Ubuntu/Kali/Debian
# Author: Dr Ayman El Hajjar

set -euo pipefail

PIN_LAB_WLAN=0
NO_REBOOT=0
for arg in "$@"; do
  case "$arg" in
    --pin-lab-wlan) PIN_LAB_WLAN=1 ;;
    --noreboot)     NO_REBOOT=1 ;;
  esac
done

echo "[i] Detecting distro..."
. /etc/os-release || true
DISTRO_ID="${ID:-unknown}"

echo "[i] Updating apt and installing build deps..."
sudo apt update -y

# Try both header patterns to cover Ubuntu/Kali kernels
sudo apt install -y dkms build-essential git libelf-dev
sudo apt install -y "linux-headers-$(uname -r)" || sudo apt install -y linux-headers-amd64 || true

REPO_DIR="/opt/rtl8812au"
MOD="8812au"

echo "[i] Fetching aircrack-ng rtl8812au..."
if [ -d "$REPO_DIR" ]; then
  sudo git -C "$REPO_DIR" reset --hard
  sudo git -C "$REPO_DIR" pull --ff-only
else
  sudo git clone https://github.com/aircrack-ng/rtl8812au.git "$REPO_DIR"
fi

cd "$REPO_DIR"
VER="$(awk -F\" '/^PACKAGE_VERSION/{print $2}' dkms.conf || true)"
[ -z "${VER:-}" ] && echo "[!] PACKAGE_VERSION not found; DKMS will infer."

echo "[i] Removing any existing 8812au DKMS builds..."
dkms status | awk -F'[ ,]+' '/8812au/{print $1,$2}' | while read -r name ver; do
  sudo dkms remove -m "$name" -v "$ver" --all || true
done

echo "[i] Adding DKMS module..."
sudo dkms add "$REPO_DIR"

echo "[i] Building & installing via DKMS..."
if [ -n "${VER:-}" ]; then
  sudo dkms build   -m "$MOD" -v "$VER"
  sudo dkms install -m "$MOD" -v "$VER"
else
  sudo dkms build   "$REPO_DIR"
  sudo dkms install "$REPO_DIR"
fi

echo "[i] Blacklisting conflicting in-kernel Realtek drivers..."
sudo tee /etc/modprobe.d/blacklist-8812au-conflicts.conf >/dev/null <<'EOF'
blacklist rtl8xxxu
blacklist rtw88_8812au
blacklist rtw88_8812a
blacklist rtw88_usb
blacklist rtw88_core
EOF

echo "[i] Updating initramfs (if available)…"
if command -v update-initramfs >/dev/null 2>&1; then
  sudo update-initramfs -u
fi

echo "[i] Switching drivers now..."
sudo modprobe -r rtl8xxxu rtw88_8812au rtw88_8812a rtw88_usb rtw88_core 2>/dev/null || true
sudo modprobe 8812au || true

if [ "$PIN_LAB_WLAN" -eq 1 ]; then
  echo "[i] Pinning Alfa as lab-wlan via udev..."
  sudo tee /etc/udev/rules.d/72-lab-wlan.rules >/dev/null <<'EOF'
SUBSYSTEM=="net", ACTION=="add", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="8812", NAME="lab-wlan"
EOF
  sudo udevadm control --reload
  sudo udevadm trigger
fi

echo "[i] Loaded modules (expect only 8812au):"
lsmod | egrep '(^8812au|^rtw88_8812au|^rtl8xxxu)' || true

if [ "$NO_REBOOT" -eq 0 ]; then
  echo "[i] Rebooting to finalize driver switch..."
  sudo reboot
else
  echo "[✓] Driver installed. Reboot recommended."
fi
