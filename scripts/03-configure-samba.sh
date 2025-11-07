#!/bin/bash
# weak Samba: guest writable share

mkdir -p /srv/samba/public
chown root:share-samba /srv/samba/public
chmod 2775 /srv/samba/public

cat > /srv/cav-csf/configs/smb.conf <<'EOF'
[global]
   workgroup = WORKGROUP
   server string = CavNet SMB
   map to guest = Bad User
   usershare allow guests = yes
   log file = /var/log/samba/log.%m
   max log size = 1000

[public]
   path = /srv/samba/public
   browseable = yes
   guest ok = yes
   read only = no
   force user = nobody
   create mask = 0666
   directory mask = 0777
EOF

cp /srv/cav-csf/configs/smb.conf /etc/samba/smb.conf
systemctl enable --now smbd
systemctl enable --now nmbd

/srv/cav-csf/scripts/checkpoint.sh "Samba configured: guest-writable share at /srv/samba/public"
