# Install GenieACS (Ubuntu 24.04)

Project ini akan membantu install GenieACS di Ubuntu 24.04 LTS (Noble Numbat) Untuk monitoring semua perangkat dibawah mikrotik yang mendukung TR-069

## Ikuti Proses nya sesuai urutan ya sayang ❤️

1. Update dan upgrade apt di Ubuntu 24.04
```bash
sudo apt update && sudo apt upgrade -y
```

2. Install dan Enable Redis & Curl
   <br>Redis adalah layanan data dama bentuk caching di memory
   <br>Curl adalah tools untuk upload download dalam jaringan
```bash
sudo apt install -y redis-server curl
sudo systemctl enable --now redis-server
```

3. 