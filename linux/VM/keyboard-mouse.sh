#!/usr/bin/env bash

ACTION="$1"

if [[ "$ACTION" != "attach" && "$ACTION" != "detach" ]]; then
    echo "Usage: $0 [attach|detach]"
    exit 1
fi

BASE_DIR="$(dirname "$0")"

KEYBOARD="$BASE_DIR/keyboard.xml"
MOUSE="$BASE_DIR/mouse.xml"

echo "=== Daftar VM ==="

# ambil list VM pakai sudo
mapfile -t vms < <(sudo virsh list --all | awk 'NR>2 && $2 != "" {print $2}')

# tampilkan list
for i in "${!vms[@]}"; do
    printf "%d. %s\n" "$((i+1))" "${vms[$i]}"
done

# input user
read -rp "Pilih nomor VM: " choice

# validasi
if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#vms[@]} )); then
    echo "❌ Input tidak valid"
    exit 1
fi

VM="${vms[$((choice-1))]}"
echo "➡️ VM dipilih: $VM"

if [[ "$ACTION" == "attach" ]]; then
    sudo virsh attach-device "$VM" "$KEYBOARD" --live
    sudo virsh attach-device "$VM" "$MOUSE" --live
    echo "✅ Keyboard & mouse di-attach ke $VM"
else
    sudo virsh detach-device "$VM" "$KEYBOARD" --live
    sudo virsh detach-device "$VM" "$MOUSE" --live
    echo "✅ Keyboard & mouse di-detach dari $VM"
fi