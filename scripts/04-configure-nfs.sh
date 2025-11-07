#!/bin/bash
# weak NFS export

cp /srv/cav-csf/configs/exports /etc/exports
chmod 644 /etc/exports

mkdir -p /srv/nfs/shared
chown -R nobody:nogroup /srv/nfs/shared || true
chmod -R 0777 /srv/nfs/shared

exportfs -rav
systemctl enable --now nfs-kernel-server

/srv/cav-csf/scripts/checkpoint.sh "NFS configured: /srv/nfs/shared exported rw,no_root_squash to 192.168.56.0/24"

echo "[OK] NFS configured"
