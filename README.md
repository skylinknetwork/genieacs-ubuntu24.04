# Install GenieACS (Ubuntu 24.04)

Project ini akan membantu install GenieACS di Ubuntu 24.04 LTS (Noble Numbat) Untuk monitoring semua perangkat dibawah mikrotik yang mendukung TR-069

## Ikuti Proses nya sesuai urutan ya sayang ❤️

### 1. Update dan upgrade apt di Ubuntu 24.04
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install dan Enable Redis & Curl</b>
Redis adalah layanan data dalam bentuk caching di memory<br>
Curl adalah tools untuk upload download dalam jaringan
```bash
sudo apt install -y redis-server curl
sudo systemctl enable --now redis-server
```

### 3. Install MongoDB 7.0
a. Download GPG Key untuk verifikasi paket MongoDB<br>
b. Menambah Repo MongoDB ke dalam system<br>
c. Update daftar paket untuk repo yang baru<br>
d. Install MongoDB dan semua paketnya<br>
e. Running otomatis MongoDB dan autostart saat server up
```bash
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable --now mongod
```

### 4. Install Node.js 20 LTS & build-essential
a. Download repo Node.js v20<br>
b. Install Node.js dan build essentialnya
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs build-essential
```

### 5. Install GenieACS via npm
Menginstal GenieACS secara global menggunakan npm<br>
NPM (Node Packet Manager) tools untuk mengelola paket
```bash
sudo npm install -g genieacs
```

### 6. Buat & aktifkan service systemd GenieACS
6.1 Buat dan setting Systemd untuk GenieACS Web UI<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Sekaligus aktifkan auto start ketika berhenti
```bash
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
```

