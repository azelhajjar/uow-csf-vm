#!/bin/bash

r="\033[1;31m"
b="\033[1;34m"
w="\033[0m"

BASHRC="$HOME/.bashrc"
BACKUP="$HOME/.bashrc.bak"
MARKER="# --- STUDENT_ID_PROMPT ---"

# Show usage message first
echo -e "${b}To set your Student ID, run: ./studentid.sh and enter your Student ID when prompted.${w}"
echo -e "${b}To reset the prompt and remove any customisations, run: ./studentid.sh --reset${w}"
echo ""

# Reset mode
if [[ "$1" == "--reset" ]]; then
    echo -e "${b}Restoring original prompt...${w}"

    if [[ -f "$BACKUP" ]]; then
        cp "$BACKUP" "$BASHRC"
        echo -e "${b}Prompt reset to default. Please restart the terminal.${w}"
    else
        echo -e "${r}Backup not found. Cannot restore original .bashrc.${w}"
    fi

    exit 0
fi

# Prompt for student ID
echo -e "${r}Please enter your Student ID:${w}"
read STUDENT_ID

# Backup once
if [[ ! -f "$BACKUP" ]]; then
    cp "$BASHRC" "$BACKUP"
fi

# Remove previous student ID customisation if script is re-run
sed -i "/$MARKER/,+1d" "$BASHRC"

# Insert student ID into Kali's existing prompt
cat >> "$BASHRC" <<EOF

$MARKER
PS1="\${PS1/\\\\u㉿\\\\h/$STUDENT_ID | \\\\u㉿\\\\h}"
EOF

echo -e "${b}Student ID prompt added. Please restart the terminal to see the change.${w}"
