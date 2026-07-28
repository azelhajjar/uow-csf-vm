#!/bin/bash

# 10 of Clubs
mkdir -p /home/artoo_detoo/music
chown artoo_detoo:users /home/artoo_detoo/music
chmod 0770 /home/artoo_detoo/music
cp ../files/flags/10_of_clubs.wav /home/artoo_detoo/music/10_of_clubs.wav
chown artoo_detoo:users /home/artoo_detoo/music/10_of_clubs.wav
chmod 0410 /home/artoo_detoo/music/10_of_clubs.wav

# 7 of Diamonds
# Assuming the Docker recipe handles Docker installation and setup

mkdir -p /opt/docker
chmod 0770 /opt/docker
cp ../files/flags/Dockerfile /opt/docker/Dockerfile
cp ../files/flags/7_of_diamonds.zip /opt/docker/7_of_diamonds.zip
chmod 0700 /opt/docker/Dockerfile /opt/docker/7_of_diamonds.zip

docker build -t 7_of_diamonds /opt/docker/
docker run --name 7_of_diamonds --restart always -itd 7_of_diamonds

rm -f /opt/docker/7_of_diamonds.zip

# Easy mode flags

# 10 of Spades
# Assuming the README app recipe handles installation and setup
mkdir -p /opt/readme_app/public/images
cp ../files/flags/flag_images/10\ of\ spades.png /opt/readme_app/public/images/10_of_spades.png
chmod 0644 /opt/readme_app/public/images/10_of_spades.png

# 8 of Clubs
for i in {1..20}
do
    mkdir -p /home/anakin_skywalker/${prev_dirs[*]}/$i
    chown anakin_skywalker:users /home/anakin_skywalker/${prev_dirs[*]}/$i
    chmod 0770 /home/anakin_skywalker/${prev_dirs[*]}/$i
    prev_dirs+=($i)
done

cp ../files/flags/flag_images/8\ of\ clubs.png /home/anakin_skywalker/${prev_dirs[*]}/8_of_clubs.png
chown anakin_skywalker:users /home/anakin_skywalker/${prev_dirs[*]}/8_of_clubs.png
chmod 0644 /home/anakin_skywalker/${prev_dirs[*]}/8_of_clubs.png

# 3 of Hearts
cp ../files/flags/flag_images/3\ of\ hearts.png /lost+found/3_of_hearts.png
chmod 0600 /lost+found/3_of_hearts.png

# 9 of Diamonds
mkdir -p /home/kylo_ren/.secret_files/
chmod 0610 /home/kylo_ren/.secret_files/
chown kylo_ren:users /home/kylo_ren/.secret_files/
cp ../files/flags/my_recordings_do_not_open.iso /home/kylo_ren/.secret_files/my_recordings_do_not_open.iso
chmod 0610 /home/kylo_ren/.secret_files/my_recordings_do_not_open.iso
chown kylo_ren:users /home/kylo_ren/.secret_files/my_recordings_do_not_open.iso

updatedb

# Hard mode flags
if [[ "$MS3_LINUX_HARD" == "true" ]]; then
    # 5 of Diamonds
    # Assuming the Knockd recipe handles installation and setup
    mkdir -p /opt/knock_knock
    chmod 0700 /opt/knock_knock
    cp ../files/flags/five_of_diamonds /opt/knock_knock/five_of_diamonds
    chmod 0700 /opt/knock_knock/five_of_diamonds
    cp ../files/flags/five_of_diamonds_srv /etc/init/five_of_diamonds_srv.conf
    chmod 0777 /etc/init/five_of_diamonds_srv.conf
    systemctl enable five_of_diamonds_srv
    systemctl start five_of_diamonds_srv

    # 2 of Spades
    cp ../files/flags/2_of_spades.pcapng /home/leia_organa/2_of_spades.pcapng
    chown leia_organa /home/leia_organa/2_of_spades.pcapng
    chmod 0600 /home/leia_organa/2_of_spades.pcapng

    # 8 of Hearts
    # Assuming the MySQL recipe handles MySQL installation and setup
    mysql -h 127.0.0.1 --user="root" --password="sploitme" --execute="CREATE DATABASE super_secret_db;"
    mysql -h 127.0.0.1 --user="root" --password="sploitme" --execute="GRANT SELECT, INSERT, DELETE, CREATE, DROP, INDEX, ALTER ON drupal.* TO 'root'@'localhost' IDENTIFIED BY 'sploitme';"
    mysql -h 127.0.0.1 --user="root" --password="sploitme" super_secret_db < flags/super_secret_db.sql

    # Joker - red
    cp ../files/flags/joker.png /etc/joker.png
    chmod 0600 /etc/joker.png
fi
