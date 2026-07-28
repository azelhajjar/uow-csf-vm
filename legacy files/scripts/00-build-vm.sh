#!/bin/bash
set -euo pipefail

exec > >(tee -a /var/log/cav-csf-build.log) 2>&1

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root (sudo)"
  exit 1
fi

echo "[INFO] Starting base VM build"

# Hostname and timezone
hostnamectl set-hostname cav-csf
timedatectl set-timezone Etc/UTC || true
sed -i '/127.0.1.1/d' /etc/hosts || true
echo "127.0.1.1 cav-csf" >> /etc/hosts

# Update and install minimal packages
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get -y install build-essential curl wget git openssh-server sudo \
  nfs-kernel-server samba vsftpd openbsd-inetd telnetd net-tools rsync smbclient \
  open-vm-tools open-vm-tools-desktop

# Create repo layout
mkdir -p /srv/cav-csf/scripts
mkdir -p /srv/cav-csf/docs
mkdir -p /srv/cav-csf/public
mkdir -p /srv/cav-csf/vulns
mkdir -p /srv/cav-csf/configs
mkdir -p /srv/cav-csf/artifacts
chmod 700 /srv/cav-csf/artifacts

# Shared directories
mkdir -p /srv/samba/public
mkdir -p /srv/nfs/shared
mkdir -p /srv/ftp
mkdir -p /opt/vulns

# Create group placeholders if missing
getent group share-samba >/dev/null || groupadd share-samba || true
getent group share-nfs >/dev/null || groupadd share-nfs || true

chgrp share-samba /srv/samba/public || true
chgrp share-nfs /srv/nfs/shared || true
chmod 2775 /srv/samba/public /srv/nfs/shared || true

# Run users setup if available
if [ -x /srv/cav-csf/scripts/01-users-setup.sh ]; then
  echo "[INFO] Running 01-users-setup.sh"
  bash /srv/cav-csf/scripts/01-users-setup.sh
else
  echo "[WARN] /srv/cav-csf/scripts/01-users-setup.sh not found. Create it and re-run."
fi

# Ensure SSH enabled
systemctl enable --now ssh || true

# Final housekeeping
apt-get -y autoremove || true
apt-get -y clean || true

echo "[DONE] Base VM prepared. /srv/cav-csf/artifacts is ready for instructor files."
echo "When ready, copy artifacts into /tmp/artifacts and run /srv/cav-csf/scripts/import-artifacts.sh"
