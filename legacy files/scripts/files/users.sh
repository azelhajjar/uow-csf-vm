#!/bin/bash

# Define an associative array for user details
declare -A users

# Assign user details
users[leia_organa]="username='leia_organa' password='help_me_obiwan' first_name='Leia' last_name='Organa' admin='true' salary='9560'"
users[luke_skywalker]="username='luke_skywalker' password='like_my_father_beforeme' first_name='Luke' last_name='Skywalker' admin='true' salary='1080'"
users[han_solo]="username='han_solo' password='nerf_herder' first_name='Han' last_name='Solo' admin='true' salary='1200'"
users[artoo_detoo]="username='artoo_detoo' password='b00p_b33p' first_name='Artoo' last_name='Detoo' admin='false' salary='22222'"
users[c_three_pio]="username='c_three_pio' password='Pr0t0c07' first_name='C' last_name='Threepio' admin='false' salary='3200'"
users[ben_kenobi]="username='ben_kenobi' password='thats_no_m00n' first_name='Ben' last_name='Kenobi' admin='false' salary='10000'"
users[darth_vader]="username='darth_vader' password='Dark_syD3' first_name='Darth' last_name='Vader' admin='false' salary='6666'"
users[anakin_skywalker]="username='anakin_skywalker' password='but_master:(' first_name='Anakin' last_name='Skywalker' admin='false' salary='1025'"
users[jarjar_binks]="username='jarjar_binks' password='mesah_p@ssw0rd' first_name='Jar-Jar' last_name='Binks' admin='false' salary='2048'"
users[lando_calrissian]="username='lando_calrissian' password='@dm1n1str8r' first_name='Lando' last_name='Calrissian' admin='false' salary='40000'"
users[boba_fett]="username='boba_fett' password='mandalorian1' first_name='Boba' last_name='Fett' admin='false' salary='20000'"
users[jabba_hutt]="username='jabba_hutt' password='my_kinda_skum' first_name='Jaba' last_name='Hutt' admin='false' salary='65000'"
users[greedo]="username='greedo' password='hanSh0tF1rst' first_name='Greedo' last_name='Rodian' admin='false' salary='50000'"
users[chewbacca]="username='chewbacca' password='rwaaaaawr8' first_name='Chewbacca' last_name='' admin='false' salary='4500'"
users[kylo_ren]="username='kylo_ren' password='Daddy_Issues2' first_name='Kylo' last_name='Ren' admin='false' salary='6667'"

# Loop through user details and create users
for user in "${!users[@]}"; do
    eval "user_details=\${users[$user]}"
    eval "$user_details"
    useradd -m -s /bin/bash -p $(openssl passwd -1 "$password") -c "$first_name $last_name" "$username"
    if [ "$admin" = "true" ]; then
        usermod -aG sudo "$username"
    fi
done
