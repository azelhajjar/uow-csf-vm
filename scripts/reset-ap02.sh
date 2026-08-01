#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WEB_ROOT="/var/www/brightleaf-ap02"

[ "${EUID:-$(id -u)}" -eq 0 ] || { printf '[ERROR] run as root with sudo\n' >&2; exit 1; }
[ -d "$WEB_ROOT" ] || { printf '[ERROR] AP-02 is not installed\n' >&2; exit 1; }

find "$WEB_ROOT" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
install -o www-data -g www-data -m 0644 "$ROOT_DIR/assets/ap02/web/index.php" "$WEB_ROOT/index.php"
chown www-data:www-data "$WEB_ROOT"
chmod 0750 "$WEB_ROOT"
systemctl restart apache2.service cav-csf-ap02-proftpd.service
"$ROOT_DIR/scripts/verify-ap02.sh"
