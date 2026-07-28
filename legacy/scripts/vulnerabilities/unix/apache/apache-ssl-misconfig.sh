#!/bin/bash
set -e

a2enmod ssl

cat << 'EOF' > /etc/apache2/conf-available/ssl-bad.conf
SSLProtocol all
SSLCipherSuite ALL:!aNULL
SSLHonorCipherOrder Off
EOF

a2enconf ssl-bad

systemctl reload apache2