#!/usr/bin/env bash
set -euo pipefail

echo "=== CAV-CSF pre-lab: dependency installation ==="
echo "[*] Run this BEFORE connecting to the host-only lab network."
echo

if ! command -v sshpass &> /dev/null; then
    echo "[*] Installing sshpass..."
    sudo apt update
    sudo apt install -y sshpass
else
    echo "[*] sshpass already installed, skipping"
fi

echo
echo "=== Installation complete ==="
echo "You can now disconnect from the internet and connect to the host-only lab network."
echo "Once connected, run fix-scripts/setup.sh"