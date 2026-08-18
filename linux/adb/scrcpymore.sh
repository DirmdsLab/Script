#!/usr/bin/env bash

export PATH="$PATH"

# Ambil daftar device yang aktif
devices=($(adb devices | awk 'NR>1 && $2=="device" {print $1}'))
device_count=${#devices[@]}

# Jika tidak ada device
if [ "$device_count" -eq 0 ]; then
  echo "Tidak ada device yang terhubung."
  exit 1
fi

# Jika lebih dari satu device, minta pengguna memilih
if [ "$device_count" -gt 1 ]; then
  echo "Terdeteksi lebih dari satu device:"
  for i in "${!devices[@]}"; do
    echo "$((i+1)). ${devices[$i]}"
  done

  read -p "Pilih nomor device (1-${device_count}): " choice
  if ! [[ "$choice" =~ ^[1-9][0-9]*$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$device_count" ]; then
    echo "Pilihan tidak valid."
    exit 1
  fi

  selected_device="${devices[$((choice-1))]}"
  serial_option="-s $selected_device"
else
  serial_option="-s ${devices[0]}"
fi

# Opsi berdasarkan mode
case "$1" in
  novideo)
    shift
    scrcpy $serial_option --no-video --window-title="Mini Desktop" --disable-screensaver "$@"
    ;;
  novirtual)
    shift
    scrcpy $serial_option --stay-awake --window-title="Mini Desktop" --disable-screensaver "$@"
    ;;
  justinput)
    shift
    scrcpy $serial_option --no-video --no-audio --stay-awake --window-title="Mini Desktop" --disable-screensaver --keyboard=uhid --mouse=uhid "$@"
    ;;
  inputandaudio)
    shift
    scrcpy $serial_option --no-video --stay-awake --window-title="Input And Audio" --disable-screensaver --keyboard=uhid --mouse=uhid "$@"
    ;;
  vlc)
    shift
    scrcpy $serial_option --new-display=1920x1080 --stay-awake --window-title='Vlc Android' --disable-screensaver --window-width=1280 --start-app=org.videolan.vlc "$@"
    ;;
  *)
    scrcpy $serial_option --new-display=1920x1080 --stay-awake --window-title="Mini Desktop" --disable-screensaver --window-width=1280 "$@"
    ;;
esac
