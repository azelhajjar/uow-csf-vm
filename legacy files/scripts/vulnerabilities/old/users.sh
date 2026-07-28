#!/bin/bash

# Load user attributes 
source ../files/users.sh

# Set starting UID
uid=1111

# Iterate over users and create them
for user_key in "${!users[@]}"; do
    if [[ $user_key == *_username ]]; then
        base_key="${user_key%_username}"
        username="${users[${base_key}_username]}"
        password_hash="${users[${base_key}_password_hash]}"

        # Create user
        useradd -m -s /bin/bash -u "$uid" -g 100 -p "$password_hash" "$username"

        # Increment UID
        ((uid++))
    fi
done


# Find administrator members
administrator_members=()
for user_key in "${!users[@]}"; do
    if [[ $user_key == *_username ]]; then
        base_key="${user_key%_username}"
        if [[ "${users[${base_key}_admin]}" == "true" ]]; then
            administrator_members+=("${users[${base_key}_username]}")
        fi
    fi
done

# Add administrator members to sudo group
if [[ ${#administrator_members[@]} -gt 0 ]]; then
    for admin in "${administrator_members[@]}"; do
        usermod -aG sudo "$admin"
    done
fi