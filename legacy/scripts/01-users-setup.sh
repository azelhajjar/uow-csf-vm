#!/bin/bash

# Groups
groupadd admins
groupadd itops
groupadd devops
groupadd finance
groupadd hr
groupadd audit
groupadd svc
groupadd backup
groupadd interns
groupadd share-samba
groupadd share-nfs

# Users
useradd -m -s /bin/bash ajones
usermod -aG admins,sudo ajones

useradd -m -s /bin/bash sthomas
usermod -aG itops sthomas

useradd -m -s /bin/bash rpatel
usermod -aG itops rpatel

useradd -m -s /bin/bash mali
usermod -aG devops mali

useradd -m -s /bin/bash jsmith
usermod -aG devops jsmith

useradd -m -s /bin/bash ewhite
usermod -aG finance ewhite

useradd -m -s /bin/bash tnguyen
usermod -aG hr tnguyen

useradd -m -s /bin/bash jyoung
usermod -aG interns jyoung

useradd -m -s /bin/bash lgreen
usermod -aG audit lgreen

useradd -m -s /bin/bash svc-backend
usermod -aG svc svc-backend
passwd -l svc-backend

useradd -m -s /bin/bash backup-bot
usermod -aG backup backup-bot
passwd -l backup-bot

# Shared dirs
mkdir -p /srv/samba/public /srv/nfs/shared /srv/ftp
chgrp share-samba /srv/samba/public
chgrp share-nfs /srv/nfs/shared
chmod 2775 /srv/samba/public /srv/nfs/shared

# Flags (org realism)
echo "user_flag{cav_intern_01}" > /home/jyoung/user_flag.txt
chown jyoung:interns /home/jyoung/user_flag.txt
chmod 640 /home/jyoung/user_flag.txt

echo "root_flag{cav_root_01}" > /root/root_flag.txt
chmod 600 /root/root_flag.txt

echo "[OK] Users and groups created."
