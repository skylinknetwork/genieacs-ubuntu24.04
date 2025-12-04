#!/bin/bash
# Simple installer GenieACS untuk Ubuntu Server 24.04
# Versi: MongoDB dari repo resmi mongodb.com
set -euo pipefail

echo ""
echo "===================================================="
echo "        GenieACS Installer - Skylink Network        "
echo "===================================================="
echo ""

# =====================================================
# 0. Deteksi user & IP otomatis
# =====================================================
echo "=== [0/6] Deteksi user & IP otomatis ==="

REAL_USER="$(logname 2>/dev/null || echo "${SUDO_USER:-}" || whoami)"
if [ "$REAL_USER" = "root" ] || [ -z "$REAL_USER" ]; then
  REAL_USER="$(getent passwd | awk -F: '$3>=1000 && $3<60000 {print $1; exit}')"
fi

REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
[ -d "$REAL_HOME" ] || REAL_HOME="/home/${REAL_USER}"

ACS_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++){if($i=="src"){print $(i+1); exit}}}')"
[ -n "${ACS_IP:-}" ] || ACS_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"

UI_JWT_SECRET="rahasia-panjang-anda"

echo "User terdeteksi  : ${REAL_USER}"
echo "Home directory   : ${REAL_HOME}"
echo "IP ACS terdeteksi: ${ACS_IP}"
echo ""
sleep 2

# =====================================================
# 1. Update sistem
# =====================================================
echo "=== [1/6] Update sistem ==="
sudo apt update && sudo apt upgrade -y

# =====================================================
# 2. Install Redis & Curl
# =====================================================
echo "=== [2/6] Install Redis & Curl ==="
sudo apt install -y redis-server curl
sudo systemctl enable --now redis-server

# =====================================================
# 3. Install MongoDB 7.0 (repo resmi mongodb.com)
# =====================================================
echo "=== [3/6] Install MongoDB 7.0 (official repo) ==="

curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable --now mongod

# =====================================================
# 4. Install Node.js 20 LTS & build-essential
# =====================================================
echo "=== [4/6] Install Node.js 20 & build tools ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs build-essential

# =====================================================
# 5. Install GenieACS via npm
# =====================================================
echo "=== [5/6] Install GenieACS ==="
sudo npm install -g genieacs

# =====================================================
# 6. Buat & aktifkan service systemd GenieACS
# =====================================================
echo "=== [6/6] Konfigurasi service GenieACS ==="

# UI service
sudo tee /etc/systemd/system/genieacs-ui.service > /dev/null << EOF
[Unit]
Description=GenieACS Web UI
After=network-online.target

[Service]
Type=simple
User=${REAL_USER}
WorkingDirectory=${REAL_HOME}
ExecStart=/usr/bin/genieacs-ui --ui-jwt-secret ${UI_JWT_SECRET}
Restart=always
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# CWMP
sudo tee /etc/systemd/system/genieacs-cwmp.service > /dev/null << EOF
[Unit]
Description=GenieACS CWMP
After=network-online.target

[Service]
ExecStart=/usr/bin/genieacs-cwmp
User=nobody
Restart=always
Environment=GENIEACS_CWMP_PORT=7547
Environment=GENIEACS_CWMP_INTERFACE=${ACS_IP}

[Install]
WantedBy=multi-user.target
EOF

# NBI
sudo tee /etc/systemd/system/genieacs-nbi.service > /dev/null << EOF
[Unit]
Description=GenieACS NBI
After=network-online.target

[Service]
ExecStart=/usr/bin/genieacs-nbi
User=nobody
Restart=always
Environment=GENIEACS_NBI_PORT=7557

[Install]
WantedBy=multi-user.target
EOF

# File server
sudo tee /etc/systemd/system/genieacs-fs.service > /dev/null << EOF
[Unit]
Description=GenieACS File Server
After=network-online.target

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

echo ""
echo "===================================================="
echo "           INSTALL SELESAI - GENIEACS OK            "
echo "===================================================="
echo ""
echo "Akses UI sekarang:"
echo "➡️  http://${ACS_IP}:3000"
echo ""
