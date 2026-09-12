#!/usr/bin/env bash
set -euo pipefail

LINUX_HOST="192.168.144.100"
LINUX_USER="uow-admin"
LINUX_PASS="uow-cavadmin"

ROBOTS_CONTENT='User-agent: *
Disallow: /admin-notes/
Disallow: /staging/
'

ADMIN_NOTES='- Rotate default credentials on staging environment before next intake
- Review firewall rules for lab segment
- Confirm backup schedule with IT
- Follow up with print server maintenance ticket
'

STAGING_HTML='<html><head><title>Staging</title></head><body><h1>Staging environment</h1><p>Not for production use.</p></body></html>'

echo "[*] Provisioning robots.txt and related content on ${LINUX_HOST}"

sshpass -p "${LINUX_PASS}" ssh -o StrictHostKeyChecking=no "${LINUX_USER}@${LINUX_HOST}" \
  "sudo mkdir -p /var/www/html/admin-notes /var/www/html/staging && \
   echo '${ROBOTS_CONTENT}' | sudo tee /var/www/html/robots.txt > /dev/null && \
   echo '${ADMIN_NOTES}' | sudo tee /var/www/html/admin-notes/todo.txt > /dev/null && \
   echo '${STAGING_HTML}' | sudo tee /var/www/html/staging/index.html > /dev/null && \
   sudo chown -R www-data:www-data /var/www/html/robots.txt /var/www/html/admin-notes /var/www/html/staging && \
   sudo find /var/www/html/admin-notes /var/www/html/staging -type d -exec chmod 0755 {} \; && \
   sudo find /var/www/html/admin-notes /var/www/html/staging -type f -exec chmod 0644 {} \;"

echo "[*] Verifying"
curl -sf "http://${LINUX_HOST}/robots.txt" && echo "[*] robots.txt live" || echo "[!] verification failed"