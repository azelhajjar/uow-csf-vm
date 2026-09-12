#!/usr/bin/env bash
set -euo pipefail

WORDLIST="/usr/share/wordlists/cav-csf-wordlist.txt"
ENTRIES=("uow-intranet" "uow-news")

# Ensure the file ends with a newline before appending, otherwise the
# first new entry gets glued onto the existing last line.
if [ -s "${WORDLIST}" ] && [ "$(tail -c1 "${WORDLIST}")" != "" ]; then
    echo "" | sudo tee -a "${WORDLIST}" > /dev/null
fi

for entry in "${ENTRIES[@]}"; do
    if grep -qxF "${entry}" "${WORDLIST}" 2>/dev/null; then
        echo "[*] '${entry}' already present in wordlist, skipping"
    else
        echo "${entry}" | sudo tee -a "${WORDLIST}" > /dev/null
        echo "[*] Added '${entry}' to wordlist"
    fi
done
