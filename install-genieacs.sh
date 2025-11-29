#!/bin/bash
# Simple installer GenieACS untuk Ubuntu Server 24.04
# Versi AUTO-DETECT USER & IP
set -euo pipefail

echo "=== [0/6] Deteksi user & IP otomatis ==="

# Deteksi user non-root yang masuk (prioritas: logname, SUDO_USER, whoami, lalu user dengan UID >= 1000)
REAL_USER="$(logname 2>/dev/null || echo "${SUDO_USER:-}" || whoami)"

# Pastikan REAL_USER itu user normal, bukan root
if [ "$REAL_USER" = "root" ] || [ -z "$REAL_USER" ]; then
  # Ambil user pertama dengan UID >= 1000
  REAL_USER="$(getent passwd | awk -F: '$3>=1000 && $3<60000 {print $1; exit}')"
fi

if [ -z "$REAL_USER" ]; then
  echo "Gagal mendeteksi user non-root. Set REAL_USER manual di script."
  exit 1
fi

REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"

if [ -z "$REAL_HOME" ] || [ ! -d "$REAL_HOME" ]; then
  REAL_HOME="/home/${REAL_USER}"
fi

# Deteksi IP utama (IPv4) yang dipakai keluar internet
ACS_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++){if($i=="src"){print $(i+1); exit}}}')"

# Fallback kalau cara di atas gagal
if [ -z "${ACS_IP:-}" ]; then
  ACS_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
fi

if [ -z "${ACS_IP:-}" ]; then
  echo "Gagal mendeteksi IP server. Set ACS_IP manual di script."
  exit 1
fi

# JWT secret bisa kamu ganti kapan-kapan, sementara pakai default dulu
UI_JWT_SECRET="rahasia-panjang-anda"

echo "User terdeteksi : ${REAL_USER}"
echo "Home directory  : ${REAL_HOME}"
echo "IP ACS terdeteksi: ${ACS_IP}"
echo "========================================="

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
User=${REAL_USER}
WorkingDirectory=${REAL_HOME}
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
