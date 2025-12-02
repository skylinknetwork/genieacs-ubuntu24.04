#!/bin/bash

read -p "Masukkan IP statis untuk ens33 (tanpa /24, contoh 10.20.20.7): " IPADDR

cat << EOF | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: false
      addresses:
        - ${IPADDR}/24
      routes:
        - to: default
          via: 10.20.20.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
EOF

sudo netplan apply
echo "Konfigurasi netplan sudah diterapkan dengan IP ${IPADDR}/24"