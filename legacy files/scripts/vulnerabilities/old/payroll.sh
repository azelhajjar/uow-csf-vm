#!/bin/bash

# Ensure MySQL, Apache, and PHP are installed and configured

# Variables
poc_dir="/home/$(getent passwd "$(getent passwd | awk -F: '{print $1}' | tail -n 1)" | cut -d: -f1)/poc/payroll_app/"

# Copy payroll_app.php file
cp /scripts/files/payroll_app/payroll_app.php /var/www/html/payroll_app.php
chmod 0755 /var/www/html/payroll_app.php

# Uncomment these lines if you need to use ERB template
# erb payroll_app/payroll.sql.erb > /tmp/payroll.sql
# chmod 0755 /tmp/payroll.sql

# Create directory for proof-of-concept
mkdir -p "$poc_dir"
chmod 0755 "$poc_dir"
chown "$(getent passwd "$(getent passwd | awk -F: '{print $1}' | tail -n 1)" | cut -d: -f1)" "$poc_dir"

# Copy poc.sh file
cp /scripts/files/payroll_app/poc.sh "${poc_dir}/poc.sh"
chmod 0755 "${poc_dir}poc.sh"

# Create payroll database and import data
mysql --socket=/var/run/mysqld/mysqld.sock --user=root --password=sploitme --execute="DROP DATABASE IF EXISTS payroll; CREATE DATABASE payroll;"
mysql --socket=/var/run/mysqld/mysqld.sock --user=root --password=sploitme payroll < /tmp/payroll.sql

# Execute payrolldb.sh to set up payroll database if needed
cd /scripts/files/payroll_app
sudo ./payrolldb.sh
