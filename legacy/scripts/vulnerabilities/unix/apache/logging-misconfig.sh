#!/bin/bash
set -e

sh -c 'echo "ErrorLog /dev/null" >> /etc/apache2/apache2.conf'
sh -c 'echo "LogLevel debug" >> /etc/apache2/apache2.conf'

systemctl reload apache2