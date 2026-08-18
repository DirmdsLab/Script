#!/usr/bin/env bash

# Cek apakah argumen port diberikan
if [ -z "$1" ]; then
  echo "Usage: $0 <port>"
  exit 1
fi

# Simpan argumen port
port=$1

# Menampilkan route dan mendapatkan IP Gateway
echo "Menampilkan route..."
ip route

# Menentukan IP Gateway (default route)
gateway_ip=$(ip route | grep default | awk '{print $3}')

# Menampilkan IP Gateway yang ditemukan
echo "IP Gateway yang ditemukan: $gateway_ip"

# Menghubungkan ke perangkat menggunakan ADB dengan port yang diberikan
echo "Menghubungkan ke perangkat ADB di $gateway_ip:$port ..."
adb connect "$gateway_ip":"$port"

echo "Selesai!"
