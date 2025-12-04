echo -e "network:\n  version: 2\n  renderer: networkd\n  ethernets:\n    ens33:\n      dhcp4: true" | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null && sudo netplan apply

sudo tee /etc/netplan/00-installer-config.yaml > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: true
EOF
sudo netplan apply