#!/bin/bash
# Simple installer GenieACS untuk Ubuntu Server 24.04
# Banner normal + progress bar stabil
set -euo pipefail

TOTAL_STEPS=6
STEP=0

banner() {
clear
echo ""
echo "===================================================="
echo "        GenieACS Installer - Skylink Network        "
echo "===================================================="
echo ""
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
# [3] Install MongoDB 7.0
# =====================================================
progress_step "Insta_
