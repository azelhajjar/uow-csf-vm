#!/usr/bin/env bash
set -euo pipefail

HOSTS_FILE="/etc/hosts"
ENTRY="192.168.144.200 uow-intranet.uow-csf.internal"

if grep -qxF "${ENTRY}" "${HOSTS_FILE}"; then
    echo "[*] Entry already present in ${HOSTS_FILE}, skipping"
else
    echo "${ENTRY}" | sudo tee -a "${HOSTS_FILE}" > /dev/null
    echo "[*] Added: ${ENTRY}"
fi