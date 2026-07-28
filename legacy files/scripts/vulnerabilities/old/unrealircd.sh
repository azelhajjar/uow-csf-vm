#!/bin/bash

# Install iptables rule
iptables -A INPUT -p tcp --dport 6697 -j ACCEPT

# Download UnrealIRCd
wget -c -t 3 -O /tmp/Unreal3.2.8.1_backdoor.tar.gz https://www.exploit-db.com/apps/752e46f2d873c1679fa99de3f52a274d-Unreal3.2.8.1_backdoor.tar_.gz

# Extract UnrealIRCd
mkdir /opt/unrealircd
tar xvfz /tmp/Unreal3.2.8.1_backdoor.tar.gz -C /opt/unrealircd
chmod 700 /opt/unrealircd/Unreal3.2

# Copy configuration files
cp ../files/unrealircd/unrealircd.conf /opt/unrealircd/Unreal3.2/unrealircd.conf
chown boba_fett /opt/unrealircd/Unreal3.2/unrealircd.conf
chmod 0400 /opt/unrealircd/Unreal3.2/unrealircd.conf

cp ../files/unrealircd/ircd.motd /opt/unrealircd/Unreal3.2/ircd.motd
chown boba_fett /opt/unrealircd/Unreal3.2/ircd.motd
chmod 0400 /opt/unrealircd/Unreal3.2/ircd.motd

# Configure and compile UnrealIRCd
cd /opt/unrealircd/Unreal3.2
./configure --with-showlistmodes --enable-hub --enable-prefixaq --with-listen=5 --with-dpath=/opt/unrealircd/Unreal3.2 --with-spath=/opt/unrealircd/Unreal3.2/src/ircd --with-nick-history=2000 --with-sendq=3000000 --with-bufferpool=18 --with-hostname=metasploitableub --with-permissions=0600 --with-fd-setsize=1024 --enable-dynamic-linking I am running a few minutes late; my previous meeting is running over.
make

# Set owner and permissions
chown -R boba_fett /opt/unrealircd
chmod 760 /etc/init.d/unrealircd

# Remove carriage returns
sed -i -e 's/\r//g' /etc/init.d/unrealircd

# Start the UnrealIRCd service
service unrealircd enable
service unrealircd start
