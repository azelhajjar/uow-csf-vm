#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== CAV-CSF pre-lab: environment setup ==="
echo "[*] Run this AFTER connecting to the host-only lab network."
echo

echo "[1/3] Fixing /etc/hosts"
bash "${SCRIPT_DIR}/fix-hosts.sh"

echo "[2/3] Updating wordlist"
bash "${SCRIPT_DIR}/fix-wordlist.sh"

echo "[3/3] Provisioning robots.txt on Linux target"
bash "${SCRIPT_DIR}/fix-linux-robots.sh"

echo
echo "=== Setup complete ==="