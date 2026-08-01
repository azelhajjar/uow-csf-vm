#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="/var/lib/cav-csf/ap01"
USERNAME="stockroom"

die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }
[ "${EUID:-$(id -u)}" -eq 0 ] || die "run as root with sudo"
[ -r "$STATE_DIR/credentials.env" ] || die "AP-01 credential state is missing"

# shellcheck disable=SC1091
. "$STATE_DIR/credentials.env"
pkill -KILL -u "$USERNAME" 2>/dev/null || true
printf '%s:%s\n' "$TEACHING_USERNAME" "$TEACHING_PASSWORD" | chpasswd
gpasswd -d "$USERNAME" sudo >/dev/null 2>&1 || true
gpasswd -d "$USERNAME" adm >/dev/null 2>&1 || true

find "/home/$USERNAME" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
cp -a /usr/share/cav-csf/ap01/home/. "/home/$USERNAME/"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"

find /srv/ftp -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
chown root:root /srv/ftp
chmod 0755 /srv/ftp
sed -e "s/@TEACHING_USERNAME@/$TEACHING_USERNAME/g" \
    -e "s/@TEACHING_PASSWORD@/$TEACHING_PASSWORD/g" \
    "$ROOT_DIR/assets/ap01/ftp/stockroom-handover.txt.in" >/srv/ftp/stockroom-handover.txt
chown root:root /srv/ftp/stockroom-handover.txt
chmod 0644 /srv/ftp/stockroom-handover.txt

SUDOERS_TEMP="$(mktemp)"
printf '%s ALL=(root) NOPASSWD: /usr/bin/find\n' "$USERNAME" >"$SUDOERS_TEMP"
chmod 0440 "$SUDOERS_TEMP"
visudo -cf "$SUDOERS_TEMP" >/dev/null
install -o root -g root -m 0440 "$SUDOERS_TEMP" /etc/sudoers.d/cav-csf-ap01-stockroom
rm -f "$SUDOERS_TEMP"
visudo -cf /etc/sudoers.d/cav-csf-ap01-stockroom >/dev/null
systemctl restart vsftpd.service cav-csf-teaching-ssh.service
"$ROOT_DIR/scripts/verify-ap01.sh"
