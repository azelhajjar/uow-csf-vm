#!/bin/bash
set -euo pipefail

if [ ! -f /srv/cav-csf/configs/user-passwords.csv ]; then
  echo "[ERROR] Password file not found: /srv/cav-csf/configs/user-passwords.csv"
  exit 1
fi

echo "[INFO] Setting user passwords from /srv/cav-csf/configs/user-passwords.csv"

while IFS=',' read -r user pass; do
  if [ "$user" = "username" ]; then
    continue
  fi

  if id "$user" >/dev/null 2>&1; then
    if [ "$pass" = "disabled" ]; then
      echo "[SKIP] $user (disabled)"
      passwd -l "$user" >/dev/null 2>&1 || true
    else
      echo "[SET] $user"
      echo "$user:$pass" | chpasswd
    fi
  else
    echo "[WARN] User $user not found, skipping"
  fi
done < /srv/cav-csf/configs/user-passwords.csv

echo "[OK] Passwords applied"
