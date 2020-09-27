#!/bin/bash

VPN_DST_PORT=9563

# Check for root priviliges
if [[ $EUID -ne 0 ]]; then
   printf "Please run as root:\nsudo %s\n" "${0}" 
   exit 1
fi

# Reset the ufw config
ufw --force reset

cp -v arch-linux-install-script/before.rules /etc/ufw
       
# block all incomming by default
ufw default deny incoming
# block all outgoing by default
ufw default deny outgoing

# Every communiction via VPN is considered to be safe
ufw allow out on tun0

# Don't block the creation of the VPN tunnel
ufw allow out $VPN_DST_PORT
# Don't block DNS queries
ufw allow out 53

# Allow out commonly used ports
ufw allow out 22,24/tcp # ,80,443/tcp
ufw allow out 8080,9050,9898,5355/tcp

# Allow local network conncection
ufw allow out to 192.168.1.0/24
ufw allow in to 192.168.1.0/24

# Enable the firewall
ufw enable