#!/bin/bash

# Define variables
RECIPE_PORT=3500
REPO_URL="https://github.com/jbarnett-r7/metasploitable3-readme.git"
APP_DIR="/opt/readme_app"
START_SCRIPT="${APP_DIR}/start.sh"
cp ../files/readme_app.conf /etc/init/readme_app.conf

INIT_SCRIPT="/etc/init/readme_app.conf"
OWNER="chewbacca"
GROUP="users"

# Install iptables rule
iptables -A INPUT -p tcp --dport "${RECIPE_PORT}" -j ACCEPT

# Clone the repository
git clone "${REPO_URL}" "${APP_DIR}"

# Set ownership and permissions
chown -R "${OWNER}:${GROUP}" "${APP_DIR}"
find "${APP_DIR}" -type f -exec chmod 0644 {} \;
find "${APP_DIR}" -type d -exec chmod 0755 {} \;
chmod 0755 "${START_SCRIPT}"

# Generate start script
cat > "${START_SCRIPT}" <<EOF
#!/bin/bash
cd "${APP_DIR}"
npm install
node server.js
EOF
chmod +x "${START_SCRIPT}"

# Create init script
cat > "${INIT_SCRIPT}" <<EOF
description "Readme App"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

chdir "${APP_DIR}"
exec "${START_SCRIPT}"
EOF
chmod 0644 "${INIT_SCRIPT}"

# Start the service
service readme_app start
