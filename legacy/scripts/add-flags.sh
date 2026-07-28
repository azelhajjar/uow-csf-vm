sudo tee /srv/cav-csf/scripts/05-add-flags.sh > /dev/null <<'EOF'
#!/bin/bash
set -euo pipefail

SAMBA_DIR="/srv/samba/public"
NFS_DIR="/srv/nfs/shared"

# detect vsftpd root
FTP_DIR=""
for cf in /etc/vsftpd-2.3.4.conf /etc/vsftpd.conf /etc/vsftpd/vsftpd.conf /etc/vsftpd/*.conf; do
  [ -f "$cf" ] || continue
  val=$(awk -F= '/^[[:space:]]*(anon_root|local_root)[[:space:]]*=/{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2}' "$cf" | tail -n1)
  if [ -n "${val:-}" ]; then
    FTP_DIR="$val"
    break
  fi
done
[ -z "$FTP_DIR" ] && FTP_DIR="/srv/ftp"

mkdir -p "$SAMBA_DIR" "$NFS_DIR" "$FTP_DIR"

echo "FLAG{SAMBA}" > "$SAMBA_DIR/FLAG_SAMBA.txt"
echo "FLAG{NFS}"   > "$NFS_DIR/FLAG_NFS.txt"
echo "FLAG{FTP}"   > "$FTP_DIR/FLAG_FTP.txt"

chmod 644 "$SAMBA_DIR/FLAG_SAMBA.txt" "$NFS_DIR/FLAG_NFS.txt" "$FTP_DIR/FLAG_FTP.txt"
chown root:root "$SAMBA_DIR/FLAG_SAMBA.txt" "$NFS_DIR/FLAG_NFS.txt" "$FTP_DIR/FLAG_FTP.txt"

rm -- "$0"
EOF

sudo chmod +x /srv/cav-csf/scripts/05-add-flags.sh
sudo /srv/cav-csf/scripts/05-add-flags.sh
