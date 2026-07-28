#!/bin/bash

# MySQL root credentials
MYSQL_ROOT_USER="root"
MYSQL_ROOT_PASSWORD="sploitme"
DATABASE_NAME="payroll"
MYSQL_USERNAME="root"
MYSQL_PASSWORD="sploitme"

# Associative array for user details
declare -A users=(
    [leia_organa]="username='leia_organa' password='help_me_obiwan' first_name='Leia' last_name='Organa' admin='true' salary='9560'"
    [luke_skywalker]="username='luke_skywalker' password='like_my_father_beforeme' first_name='Luke' last_name='Skywalker' admin='true' salary='1080'"
    [han_solo]="username='han_solo' password='nerf_herder' first_name='Han' last_name='Solo' admin='true' salary='1200'"
    [artoo_detoo]="username='artoo_detoo' password='b00p_b33p' first_name='Artoo' last_name='Detoo' admin='false' salary='22222'"
    [c_three_pio]="username='c_three_pio' password='Pr0t0c07' first_name='C' last_name='Threepio' admin='false' salary='3200'"
    [ben_kenobi]="username='ben_kenobi' password='thats_no_m00n' first_name='Ben' last_name='Kenobi' admin='false' salary='10000'"
    [darth_vader]="username='darth_vader' password='Dark_syD3' first_name='Darth' last_name='Vader' admin='false' salary='6666'"
    [anakin_skywalker]="username='anakin_skywalker' password='but_master:(' first_name='Anakin' last_name='Skywalker' admin='false' salary='1025'"
    [jarjar_binks]="username='jarjar_binks' password='mesah_p@ssw0rd' first_name='Jar-Jar' last_name='Binks' admin='false' salary='2048'"
    [lando_calrissian]="username='lando_calrissian' password='@dm1n1str8r' first_name='Lando' last_name='Calrissian' admin='false' salary='40000'"
    [boba_fett]="username='boba_fett' password='mandalorian1' first_name='Boba' last_name='Fett' admin='false' salary='20000'"
    [jabba_hutt]="username='jabba_hutt' password='my_kinda_skum' first_name='Jaba' last_name='Hutt' admin='false' salary='65000'"
    [greedo]="username='greedo' password='hanSh0tF1rst' first_name='Greedo' last_name='Rodian' admin='false' salary='50000'"
    [chewbacca]="username='chewbacca' password='rwaaaaawr8' first_name='Chewbacca' last_name='' admin='false' salary='4500'"
    [kylo_ren]="username='kylo_ren' password='Daddy_Issues2' first_name='Kylo' last_name='Ren' admin='false' salary='6667'"
)

# Grant privileges to MySQL root user
echo "Granting privileges to MySQL root user..."
mysql -u$MYSQL_ROOT_USER -p$MYSQL_ROOT_PASSWORD <<MYSQL_SCRIPT
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' IDENTIFIED BY 'sploitme' WITH GRANT OPTION;
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'sploitme';
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$MYSQL_USERNAME'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Check if MySQL command was successful
if [ $? -eq 0 ]; then
    echo "MySQL user privileges granted successfully."
else
    echo "Error: Failed to grant MySQL user privileges."
    exit 1
fi

# SQL commands to create users table and insert data
echo "Creating users table and inserting data..."
mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD $DATABASE_NAME <<MYSQL_SCRIPT
DROP TABLE IF EXISTS users;
CREATE TABLE users (
    username VARCHAR(30) NOT NULL,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    password VARCHAR(40) NOT NULL,
    salary INT NOT NULL,
    admin VARCHAR(5) NOT NULL
);
MYSQL_SCRIPT

# Loop through user details and insert into users table
for user in "${!users[@]}"; do
    eval "user_details=\${users[$user]}"
    eval "$user_details"
    mysql -u$MYSQL_USERNAME -p$MYSQL_PASSWORD $DATABASE_NAME <<MYSQL_SCRIPT
    INSERT INTO users (username, first_name, last_name, password, salary, admin) VALUES ('$username', '$first_name', '$last_name', '$password', $salary, '$admin');
MYSQL_SCRIPT
done

echo "Users table created and data inserted successfully."

# Update PHP MySQL connection details
echo "Updating PHP MySQL connection details..."
PHP_FILE="/var/www/html/payroll_app.php"

# Make sure the PHP file exists
if [ ! -f "$PHP_FILE" ]; then
    echo "Error: PHP file '$PHP_FILE' not found."
    exit 1
fi

# Update connection details in PHP file
sed -i "s/\$username = '.*';/\$username = '$MYSQL_USERNAME';/" $PHP_FILE
sed -i "s/\$password = '.*';/\$password = '$MYSQL_PASSWORD';/" $PHP_FILE
sed -i "s/\$dbname = '.*';/\$dbname = '$DATABASE_NAME';/" $PHP_FILE

echo "PHP MySQL connection details updated successfully."

# Restart MySQL service
echo "Restarting MySQL service..."
sudo systemctl restart mysql

# Check if MySQL service restarted successfully
if [ $? -eq 0 ]; then
    echo "MySQL service restarted successfully."
else
    echo "Error: Failed to restart MySQL service."
    exit 1
fi

echo "Setup completed successfully."
