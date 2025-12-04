#!/bin/bash
# Restore semua config, VP, presets, provisions dari file genieacs-ui-full.tar.gz

set -e

echo "=== [1/5] Download file UI full dari GitHub ==="
curl -fsSL -o /tmp/genieacs-ui-full.tar.gz \
  https://raw.githubusercontent.com/skylinknetwork/genieacs-ubuntu24.04/main/genieacs.tar.gz

echo "=== [2/5] Extract file ==="
rm -rf /tmp/genieacs-ui-full
tar xzf /tmp/genieacs-ui-full.tar.gz -C /tmp

echo "=== [3/5] Hapus koleksi lama di MongoDB ==="
mongosh genieacs --eval "db.config.drop()"
mongosh genieacs --eval "db.provisions.drop()"
mongosh genieacs --eval "db.virtualParameters.drop()"
mongosh genieacs --eval "db.presets.drop()"
mongosh genieacs --eval "db.users.drop()"

echo "=== [4/5] Restore koleksi baru ==="
mongorestore --db genieacs /tmp/genieacs-ui-full/genieacs

echo "=== [5/5] Restart GenieACS UI ==="
sudo systemctl restart genieacs-ui

echo "==============================================="
echo "RESTORE SELESAI!"
echo "Silakan buka kembali GenieACS di browser."
echo "==============================================="
