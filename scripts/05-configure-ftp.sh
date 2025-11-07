#!/usr/bin/env bash
set -e

# One-shot provisioning script to install and run vulnerable vsftpd 2.3.4
# Assumes the vsftpd tarball exists at /srv/cav-csf/artifacts/vsftpd.tar.gz and will be extracted
# Must be run as root

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root (sudo)"
  exit 1
fi

# Stop and disable packaged vsftpd to free port 21
systemctl stop vsftpd || true
systemctl disable vsftpd || true

# Install 32-bit support and required 32-bit libraries
dpkg --add-architecture i386
apt update
apt install -y libc6:i386 libstdc++6:i386 libgcc-s1:i386 libpam0g:i386 libcap2:i386 libaudit1:i386 libcap-ng0:i386

# Prepare /opt and install binary
mkdir -p /opt/vsftpd-2.3.4/sbin

# Extract provided tarball (expected to contain the vsftpd binary)
if [ -f /srv/cav-csf/artifacts/vsftpd.tar.gz ]; then
  rm -rf /tmp/vsftpd-extract
  mkdir -p /tmp/vsftpd-extract
  tar -xzf /srv/cav-csf/artifacts/vsftpd.tar.gz -C /tmp/vsftpd-extract
  SRC_BIN=$(find /tmp/vsftpd-extract -type f -name vsftpd | head -n1 || true)
  if [ -z "$SRC_BIN" ]; then
    echo "/srv/cav-csf/artifacts/vsftpd.tar.gz did not contain a vsftpd binary" >&2
    exit 1
  fi
  cp "$SRC_BIN" /opt/vsftpd-2.3.4/sbin/vsftpd
else
  echo "/srv/cav-csf/artifacts/vsftpd.tar.gz not found. Place the tarball there before running this script." >&2
  exit 1
fi

chown root:root /opt/vsftpd-2.3.4/sbin/vsftpd
chmod 755 /opt/vsftpd-2.3.4/sbin/vsftpd

# Create compatibility symlink for libcap if needed
if [ ! -e /lib/i386-linux-gnu/libcap.so.1 ]; then
  ln -sf /lib/i386-linux-gnu/libcap.so.2 /lib/i386-linux-gnu/libcap.so.1 || true
fi

# Create minimal vulnerable config (systemd-managed, background disabled)
cat > /opt/vsftpd-2.3.4/vsftpd.conf <<'EOF'
listen=YES
listen_port=21
anonymous_enable=YES
local_enable=YES
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_root=/srv/ftp
ftpd_banner=Welcome to the vulnerable vsftpd 2.3.4 service
pasv_enable=YES
pasv_min_port=21000
pasv_max_port=21010
xferlog_enable=YES
background=NO
secure_chroot_dir=/usr/share/empty
EOF

# Prepare FTP root and chroot dir
mkdir -p /srv/ftp
chown -R nobody:nogroup /srv/ftp
chmod -R 755 /srv/ftp
mkdir -p /usr/share/empty
chmod 755 /usr/share/empty

# Create systemd service for the vulnerable binary
cat > /etc/systemd/system/vsftpd-2.3.4.service <<'EOF'
[Unit]
Description=vsftpd 2.3.4 lab service
After=network.target

[Service]
ExecStart=/opt/vsftpd-2.3.4/sbin/vsftpd /opt/vsftpd-2.3.4/vsftpd.conf
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# Finalize and start service
systemctl daemon-reload
systemctl enable --now vsftpd-2.3.4.service

# Self-destruct (one-shot provisioning)
rm -f -- "$0"

exit 0
