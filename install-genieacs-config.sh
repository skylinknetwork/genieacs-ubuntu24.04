#!/usr/bin/env bash
set -euo pipefail

echo "=== GenieACS UI config restore (from GitHub) ==="

GITHUB_USER="skylinknetwork"
REPO="genieacs-ubuntu24.04"
CONFIG_TAR="genieacs-config.tar.gz"
RAW_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${REPO}/main/${CONFIG_TAR}"

TAR_PATH="/tmp/${CONFIG_TAR}"
EXTRACT_DIR="/tmp/genieacs-config"

echo "[1/5] Cek dependency (mongosh, mongorestore, curl/wget)..."

if ! command -v mongosh >/dev/null 2>&1; then
  echo "Error: 'mongosh' tidak ditemukan. Pastikan MongoDB 7 sudah ter-install."
  exit 1
fi

if ! command -v mongorestore >/dev/null 2>&1; then
  echo "Error: 'mongorestore' tidak ditemukan. Biasanya ada di paket mongodb-database-tools."
  exit 1
fi

DL_CMD=""
if command -v curl >/dev/null 2>&1; then
  DL_CMD="curl -fsSL \"$RAW_URL\" -o \"$TAR_PATH\""
elif command -v wget >/dev/null 2>&1; then
  DL_CMD="wget -q \"$RAW_URL\" -O \"$TAR_PATH\""
else
  echo "Error: tidak ada 'curl' atau 'wget'. Install salah satu dulu."
  exit 1
fi

echo "[2/5] Download config dump dari GitHub:"
echo "       $RAW_URL"
rm -f "$TAR_PATH"
eval "$DL_CMD"

if [ ! -f "$TAR_PATH" ]; then
  echo "Error: file $TAR_PATH tidak ditemukan setelah download."
  exit 1
fi

echo "[3/5] Extract arsip ke $EXTRACT_DIR ..."
rm -rf "$EXTRACT_DIR"
mkdir -p /tmp
tar xzf "$TAR_PATH" -C /tmp

# Struktur hasil mongodump yang kita pakai sebelumnya:
# /tmp/genieacs-config/genieacs/config.bson
BSON_PATH="${EXTRACT_DIR}/genieacs/config.bson"

if [ ! -f "$BSON_PATH" ]; then
  echo "Error: config.bson tidak ditemukan di $BSON_PATH"
  echo "Cek lagi isi genieacs-config.tar.gz di repo GitHub-mu."
  exit 1
fi

echo "[4/5] Hapus config lama di database 'genieacs.config' ..."
mongosh --quiet <<'EOF'
db = db.getSiblingDB("genieacs");
const res = db.config.deleteMany({});
print("Dokumen config lama terhapus:", res.deletedCount);
EOF

echo "[5/5] Restore koleksi config dari dump ..."
mongorestore \
  --host 127.0.0.1 \
  --port 27017 \
  --db genieacs \
  --collection config \
  --drop \
  "$BSON_PATH"

echo "Restart service genieacs-ui (kalau ada)..."
if systemctl list-unit-files | grep -q '^genieacs-ui\.service'; then
  sudo systemctl restart genieacs-ui
  echo "genieacs-ui direstart."
else
  echo "Service genieacs-ui tidak ditemukan, lewati restart."
fi

echo "=== Selesai: config GenieACS berhasil di-restore. ==="
echo "Silakan cek UI: http://IP_SERVER:3000/#/overview dan Admin > Config."
