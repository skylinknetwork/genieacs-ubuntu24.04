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

### 3. Install MongoDB 7.0 (repo resmi mongodb.com)
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl enable --now mongod