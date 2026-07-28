#!/bin/bash
# ONE_SHOT - full VM build status summary
echo "=============================="
echo "  CAV-CSF VM STATUS SUMMARY"
echo "=============================="
echo

if [ -f /srv/cav-csf/checkpoints/latest.txt ]; then
  echo "Last checkpoint:"
  cat /srv/cav-csf/checkpoints/latest.txt
else
  echo "No checkpoint found."
fi

echo
echo "Active services:"
systemctl list-units --type=service --state=running | egrep 'smbd|nmbd|nfs|vsftpd|apache-elf|telnet|ssh' || echo "None"

echo
echo "Listening ports:"
ss -tuln | awk 'NR==1 || /:21 |:22 |:23 |:80 |:139 |:445 |:2049 |:2121 / {print}' || echo "None"

echo
echo "Configured shares (Samba/NFS):"
if [ -f /srv/cav-csf/configs/smb.conf ]; then
  echo "- Samba shares:"
  grep '^\[' /srv/cav-csf/configs/smb.conf | sed 's/\[//;s/\]//'
fi
if [ -f /srv/cav-csf/configs/exports ]; then
  echo "- NFS exports:"
  cat /srv/cav-csf/configs/exports
fi

echo
echo "Lab services configuration:"
if systemctl is-active --quiet apache-elf; then
  echo "- Apache Server: running"
else
  echo "- Apache Server: stopped"
fi

if systemctl is-active --quiet vsftpd-2.3.4.service; then
  echo "- vsftpd 2.3.4: running"
else
  echo "- vsftpd 2.3.4: stopped"
fi

if systemctl is-active --quiet nfs-kernel-server; then
  echo "- NFS server: running"
else
  echo "- NFS server: stopped"
fi

if systemctl is-active --quiet smbd nmbd; then
  echo "- Samba: running"
else
  echo "- Samba: stopped"
fi

if systemctl is-active --quiet ssh; then
  echo "- SSH: running"
else
  echo "- SSH: stopped"
fi

if systemctl is-active --quiet openbsd-inetd; then
  echo "- Telnet: running"
else
  echo "- Telnet: stopped"
fi

echo
echo "Artifacts staged (ready to import):"
if ls /srv/cav-csf/artifacts/*.sh >/dev/null 2>&1; then
  echo "- /srv/cav-csf/artifacts:"
  ls -1 /srv/cav-csf/artifacts/*.sh | sed 's|/srv/cav-csf/artifacts/||'
else
  echo "- /srv/cav-csf/artifacts: none"
fi

echo
echo "=============================="
echo "End of summary."
echo "=============================="
