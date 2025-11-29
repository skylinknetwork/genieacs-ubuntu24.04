#!/bin/bash
# Simple installer GenieACS untuk Ubuntu Server 24.04
# Versi AUTO-DETECT USER & IP + Banner + Progress bar
set -euo pipefail

# Warna
YELLOW='\e[33;1m'
WHITE='\e[97;1m'
NC='\e[0m'

TOTAL_STEPS=6
STEP=0

banner() {
  clear
  # "flash" kuning-putih sekali
  echo -e "${YELLOW}"
  echo "=================================================================="
  echo "               GenieACS Installer - Skylink Network"
  echo "=================================================================="
  echo -e "${NC}"
  sleep 0.25
  clear
  echo -e "${WHITE}"
  echo "=================================================================="
  echo "               GenieACS Installer - Skylink Network"
  echo "=================================================================="
  echo -e "${NC}"
}

progress_step() {
  STEP=$((STEP+1))
  banner
  local percent=$(( STEP * 100 / TOTAL_STEPS ))
  local filled=$(( STEP * 20 / TOTAL_STEPS ))
  local empty=$((20 - filled))

  printf "Progress: ["
  for _ in $(seq 1 $filled); do printf "#"; done
  for _ in $(seq 1 $empty);  do printf " "; done
  printf "] %3d%%\n\n" "$percent"

  echo "=== [$STEP/$TOTAL_STEPS] $1 ==="
  echo
}

# =====================================================
# [0] Deteksi user & IP
# =====================================================
progress_step "Deteksi user & IP otomatis"

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
sleep 2

# =====================================================
# [1] Update sistem
# =====================================================
progress_step "Update sistem"
sudo apt update && sudo apt upgrade -y

# =====================================================
# [2] Install Redis & Curl
# =====================================================
progress_step "Install Redis & Curl"
sudo apt install -y redis-server curl
sudo systemctl enable --now redis-server

# =====================================================
# [3] Install MongoDB
# =====================================================
progress_step "Install MongoDB 7.0"
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable --now mongod

# =====================================================
# [4] Install Node.js 20
# =====================================================
progress_step "Install Node.js 20 + build-essential"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs build-essential

# =====================================================
# [5] Install GenieACS
# =====================================================
progress_step "Install GenieACS via npm"
sudo npm install -g genieacs

# =====================================================
# [6] Buat service systemd
# =====================================================
progress_step "Buat & aktifkan service systemd"

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

progress_step "SELESAI"
echo "GenieACS seharusnya sudah jalan."
echo "Coba akses: http://${ACS_IP}:3000"
echo
