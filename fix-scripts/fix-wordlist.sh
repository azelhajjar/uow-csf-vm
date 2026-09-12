cat > fix-wordlist.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

WORDLIST="/usr/share/wordlists/cav-csf-wordlist.txt"
ENTRIES=("uow-intranet" "uow-news")

for entry in "${ENTRIES[@]}"; do
    if grep -qxF "${entry}" "${WORDLIST}" 2>/dev/null; then
        echo "[*] '${entry}' already present in wordlist, skipping"
    else
        echo "${entry}" | sudo tee -a "${WORDLIST}" > /dev/null
        echo "[*] Added '${entry}' to wordlist"
    fi
done
EOF
