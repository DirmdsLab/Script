#!/usr/bin/env bash

ACTION="$1"

if [[ "$ACTION" != "attach" && "$ACTION" != "detach" ]]; then
    echo "Usage: $0 [attach|detach]"
    exit 1
fi

BASE_DIR="$(dirname "$0")"
KEYBOARD="$BASE_DIR/keyboard.xml"
MOUSE="$BASE_DIR/mouse.xml"

echo "=== VM List ==="

# Get VM list using sudo
mapfile -t vms < <(sudo virsh list --all | awk 'NR>2 && $2 != "" {print $2}')

# Display VM list
for i in "${!vms[@]}"; do
    printf "%d. %s\n" "$((i+1))" "${vms[$i]}"
done

# Get user input
read -rp "Select VM number: " choice

# Validate input
if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#vms[@]} )); then
    echo "Invalid input"
    exit 1
fi

VM="${vms[$((choice-1))]}"

echo "Selected VM: $VM"

if [[ "$ACTION" == "attach" ]]; then
    sudo virsh attach-device "$VM" "$KEYBOARD" --live
    sudo virsh attach-device "$VM" "$MOUSE" --live
    echo "Keyboard & mouse attached to $VM"
else
    sudo virsh detach-device "$VM" "$KEYBOARD" --live
    sudo virsh detach-device "$VM" "$MOUSE" --live
    echo "Keyboard & mouse detached from $VM"
fi