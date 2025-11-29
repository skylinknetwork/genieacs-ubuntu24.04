#!/usr/bin/env bash
set -euo pipefail

echo "========================================================"
echo "         GenieACS FULL INSTALLER + UI RESTORE"
echo "========================================================"

GITHUB_USER="skylinknetwork"
REPO="genieacs-ubuntu24.04"
CONFIG_TAR="genieacs-config.tar.gz"
RAW_TAR_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/${CONFIG_TAR}"
INSTALLER_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/install-genieacs.sh"

echo "STEP 1: Install GenieACS core..."
bash <(curl -fsSL "$INSTALLER_URL")

echo "STEP 2: Download UI config dump..."
TAR_PATH="/tmp/${CONFIG_TAR}"
EXTRACT_DIR="/tmp/genieacs-config"

rm -f "$TAR_PATH"
rm -rf "$EXTRACT_DIR"

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$RAW_TAR_URL" -o "$TAR_PATH"
else
  wget -q "$RAW_TAR_URL" -O "$TAR_PATH"
fi

if [ ! -f "$TAR_PATH" ]; then
  echo "ERROR: Tidak bisa download config tar.gz!"
  exit 1
fi

echo "STEP 3: Extract config..."
mkdir -p /tmp
tar xzf "$TAR_PATH" -C /tmp

BSON_PATH="${EXTRACT_DIR}/genieacs/config.bson"

if [ ! -f "$BSON_PATH" ]; then
  echo "ERROR: config.bson tidak ditemukan!"
  exit 1
fi

echo "STEP 4: Hapus konfigurasi lama di MongoDB..."
mongosh --quiet <<'EOF'
db = db.getSiblingDB("genieacs");
db.config.deleteMany({});
EOF

echo "STEP 5: Restore konfigurasi UI..."
mongorestore \
  --host 127.0.0.1 \
  --port 27017 \
  --db genieacs \
  --collection config \
  --drop \
  "$BSON_PATH"

echo "STEP 6: Restart semua service GenieACS..."
sudo systemctl restart genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui

echo "========================================================"
echo "    INSTALASI COMPLETE! GenieACS SIAP DIPAKAI!"
echo "========================================================"
echo "Buka browser: http://IP-SERVER:3000"
echo "ACS + UI + Chart + Layout = restored full."
