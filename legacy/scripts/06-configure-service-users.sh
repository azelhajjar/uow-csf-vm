#!/bin/bash
set -euo pipefail

# One-shot provisioning script to bind existing users to Samba, NFS and FTP services
# Uses real accounts from /srv/cav-csf/configs/user-passwords.csv
# Must be run as root in the defined VM build sequence

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root (sudo)"
  exit 1
fi

# Group setup
groupadd -f share-samba
groupadd -f share-nfs

# User-to-group mapping
usermod -aG share-samba ajones
usermod -aG share-samba sthomas
usermod -aG share-samba jsmith

usermod -aG share-nfs rpatel
usermod -aG share-nfs mali
usermod -aG share-nfs jsmith

# Samba credentials setup
for user in ajones sthomas jsmith; do
  password=$(grep -E "^${user}," /srv/cav-csf/configs/user-passwords.csv | cut -d',' -f2)
  (echo "$password"; echo "$password") | smbpasswd -a -s "$user"
done

# Permissions for Samba and NFS shares
chgrp -R share-samba /srv/samba/public
chmod 2775 /srv/samba/public

chgrp -R share-nfs /srv/nfs/shared
chmod 2775 /srv/nfs/shared

# VSFTPD configuration adjustments
if grep -qE "^local_enable=" /opt/vsftpd-2.3.4/vsftpd.conf; then
  sed -i "s|^local_enable=.*|local_enable=YES|" /opt/vsftpd-2.3.4/vsftpd.conf
else
  echo "local_enable=YES" >> /opt/vsftpd-2.3.4/vsftpd.conf
fi

if grep -qE "^write_enable=" /opt/vsftpd-2.3.4/vsftpd.conf; then
  sed -i "s|^write_enable=.*|write_enable=YES|" /opt/vsftpd-2.3.4/vsftpd.conf
else
  echo "write_enable=YES" >> /opt/vsftpd-2.3.4/vsftpd.conf
fi

if grep -qE "^chroot_local_user=" /opt/vsftpd-2.3.4/vsftpd.conf; then
  sed -i "s|^chroot_local_user=.*|chroot_local_user=NO|" /opt/vsftpd-2.3.4/vsftpd.conf
else
  echo "chroot_local_user=NO" >> /opt/vsftpd-2.3.4/vsftpd.conf
fi

if grep -qE "^userlist_enable=" /opt/vsftpd-2.3.4/vsftpd.conf; then
  sed -i "s|^userlist_enable=.*|userlist_enable=NO|" /opt/vsftpd-2.3.4/vsftpd.conf
else
  echo "userlist_enable=NO" >> /opt/vsftpd-2.3.4/vsftpd.conf
fi

# FTP home directories
mkdir -p /srv/ftp/rpatel
chown rpatel:rpatel /srv/ftp/rpatel
chmod 755 /srv/ftp/rpatel
echo "Welcome rpatel" > /srv/ftp/rpatel/README.txt

mkdir -p /srv/ftp/mali
chown mali:mali /srv/ftp/mali
chmod 755 /srv/ftp/mali
echo "Welcome mali" > /srv/ftp/mali/README.txt

mkdir -p /srv/ftp/jsmith
chown jsmith:jsmith /srv/ftp/jsmith
chmod 755 /srv/ftp/jsmith
echo "Welcome jsmith" > /srv/ftp/jsmith/README.txt

# Anonymous upload permissions
chown -R nobody:nogroup /srv/ftp
chmod -R 755 /srv/ftp

# Restart services
systemctl restart smbd
systemctl restart nmbd
systemctl restart vsftpd-2.3.4.service
exportfs -ra

# Summary
echo "[DONE] Service users configured:"
echo "  Samba users: ajones, sthomas, jsmith"
echo "  NFS users: rpatel, mali, jsmith"
echo "  FTP local dirs: /srv/ftp/rpatel /srv/ftp/mali /srv/ftp/jsmith"

echo "[INFO] Script name: 06-configure-service-users.sh"
