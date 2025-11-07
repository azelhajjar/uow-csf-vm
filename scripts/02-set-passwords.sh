#!/bin/bash
set -euo pipefail

CSV="/srv/cav-csf/configs/user-passwords.csv"

if [ ! -f "$CSV" ]; then
  echo "[ERROR] Password file not found: $CSV"
  exit 1
fi

echo "[INFO] Setting user passwords from $CSV"

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
done < "$CSV"

echo "[OK] Passwords applied"
