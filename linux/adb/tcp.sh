#!/usr/bin/env bash

# Step 1: Get list of connected devices
devices=($(adb devices | grep -w "device" | awk '{print $1}'))

# Step 2: Check if there are devices
if [ ${#devices[@]} -eq 0 ]; then
  echo "❌ Tidak ada device yang terhubung."
  exit 1
fi

# Step 3: Tampilkan menu awal
echo "Pilih aksi utama:"
echo "[0] Disconnect port"
echo "[1] Connect (forward/reverse)"
echo "[2] List Port"
read -p "Masukkan pilihan (0/2): " main_action

if [ "$main_action" = "0" ] || [ "$main_action" = "1" ]; then
    :
elif [ "$main_action" = "2" ]; then
    adb forward --list
    exit 0
else
    echo "❌ Opsi tidak valid."
    exit 1
fi


# Step 4: Pilih device
echo "📱 Daftar device yang terhubung:"
for i in "${!devices[@]}"; do
  echo "[$i] ${devices[$i]}"
done

read -p "Pilih device (0-${#devices[@]}): " device_index

if ! [[ "$device_index" =~ ^[0-9]+$ ]] || [ "$device_index" -ge "${#devices[@]}" ]; then
  echo "❌ Pilihan tidak valid."
  exit 1
fi

selected_device=${devices[$device_index]}
echo "✅ Device yang dipilih: $selected_device"

# Step 5: Disconnect port
if [ "$main_action" == "0" ]; then
  echo "Masukkan port yang ingin di-disconnect (pisahkan dengan spasi):"
  read -a ports

  for port in "${ports[@]}"; do
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
      echo "❌ Port tidak valid: $port"
      exit 1
    fi
  done

  for port in "${ports[@]}"; do
    echo "🔌 Memutus forward tcp:$port (jika ada)"
    adb -s "$selected_device" forward --remove tcp:$port

    echo "🔌 Memutus reverse tcp:$port (jika ada)"
    adb -s "$selected_device" reverse --remove tcp:$port
  done

  echo "✅ Semua port telah diputus."
  exit 0
fi

# Step 6: Connect (forward/reverse)
echo "Pilih metode koneksi:"
echo "[0] Forward port (device -> host)"
echo "[1] Reverse port (host -> device)"
read -p "Pilih opsi (0/1): " action

if [ "$action" != "0" ] && [ "$action" != "1" ]; then
  echo "❌ Opsi tidak valid."
  exit 1
fi

# Step 7: Masukkan satu atau lebih port
read -p "Masukkan port yang ingin di-forward/reverse (pisahkan dengan spasi): " -a ports

# Validasi port
for port in "${ports[@]}"; do
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "❌ Port tidak valid: $port"
    exit 1
  fi
done

# Step 8: Jalankan forward/reverse
for port in "${ports[@]}"; do
  if [ "$action" == "0" ]; then
    echo "➡️  Forwarding tcp:$port -> tcp:$port untuk $selected_device"
    adb -s "$selected_device" forward tcp:$port tcp:$port
  else
    echo "⬅️  Reversing tcp:$port -> tcp:$port untuk $selected_device"
    adb -s "$selected_device" reverse tcp:$port tcp:$port
  fi
done

echo "✅ Semua port telah diproses."
