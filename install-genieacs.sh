#!/bin/bash
# Simple installer GenieACS untuk Ubuntu Server 24.04
# Sesuaikan USER_LINUX dan ACS_IP di bawah sebelum dipakai massal

set -e

USER_LINUX="skylink"
ACS_IP="10.20.20.5"
UI_JWT_SECRET="rahasia-panjang-anda"

echo "=== [1/6] Update sistem ==="
sudo apt update && sudo apt upgrade -y

echo "=== [2/6] Install Redis & Curl ==="
sudo apt install -y redis-server curl
sudo systemctl enable --now redis-server

echo "=== [3/6] Install MongoDB 7.0 (repo jammy) ==="
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable --now mongod

echo "=== [4/6] Install Node.js 20 LTS & build-essential ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs build-essential

echo "=== [5/6] Install GenieACS via npm ==="
sudo npm install -g genieacs

echo "=== [6/6] Buat & aktifkan service systemd GenieACS ==="

# ====== Service: genieacs-ui ======
sudo tee /etc/systemd/system/genieacs-ui.service > /dev/null << EOF
[Unit]
Description=GenieACS Web UI
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${USER_LINUX}
WorkingDirectory=/home/${USER_LINUX}
ExecStart=/usr/bin/genieacs-ui --ui-jwt-secret ${UI_JWT_SECRET}
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# ====== Service: genieacs-cwmp ======
sudo tee /etc/systemd/system/genieacs-cwmp.service > /dev/null << EOF
[Unit]
Description=GenieACS CWMP
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/genieacs-cwmp
User=nobody
Restart=always
Environment=GENIEACS_CWMP_PORT=7547
Environment=GENIEACS_CWMP_INTERFACE=${ACS_IP}

[Install]
WantedBy=multi-user.target
EOF

# ====== Service: genieacs-nbi ======
sudo tee /etc/systemd/system/genieacs-nbi.service > /dev/null << EOF
[Unit]
Description=GenieACS NBI
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/genieacs-nbi
User=nobody
Restart=always
Environment=GENIEACS_NBI_PORT=7557

[Install]
WantedBy=multi-user.target
EOF

# ====== Service: genieacs-fs ======
sudo tee /etc/systemd/system/genieacs-fs.service > /dev/null << EOF
[Unit]
Description=GenieACS File Server
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/genieacs-fs
User=nobody
Restart=always
Environment=GENIEACS_FS_PORT=7567

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now genieacs-ui genieacs-cwmp genieacs-nbi genieacs-fs

echo "=== SELESAI ==="
echo "GenieACS seharusnya sudah jalan."
echo "Coba akses: http://${ACS_IP}:3000"
