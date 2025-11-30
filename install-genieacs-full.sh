#!/bin/bash
# Full installer GenieACS + UI config (Skylink Network)
# Repo: https://github.com/skylinknetwork/genieacs-ubuntu24.04

set -euo pipefail

BANNER_LINE="===================================================="

banner() {
  clear
  echo ""
  echo "$BANNER_LINE"
  echo "        GenieACS Installer - Skylink Network        "
  echo "$BANNER_LINE"
  echo ""
}

banner
echo "[INFO] Menjalankan install GenieACS core..."
echo

BASE_URL="https://raw.githubusercontent.com/skylinknetwork/genieacs-ubuntu24.04/main"

# 1) Install core GenieACS (Redis, MongoDB, Node.js, service, dll)
bash <(curl -fsSL "${BASE_URL}/install-genieacs.sh")

banner
echo "[INFO] Install GenieACS core SELESAI."
echo
echo "[INFO] Melanjutkan: restore UI config (charts, presets, provisions, dll)..."
echo

# 2) Restore UI / konfigurasi lengkap
bash <(curl -fsSL "${BASE_URL}/install-genieacs-ui-full.sh")

banner
echo "[DONE] Semua proses selesai."
echo "Silakan akses GenieACS di browser:"
echo
echo "  -> http://ALAMAT_IP_SERVER:3000"
echo
echo "Ganti 'ALAMAT_IP_SERVER' dengan IP Ubuntu kamu."
echo
