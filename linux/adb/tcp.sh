#!/usr/bin/env bash

# Get the list of connected Android devices
mapfile -t devices < <(
    adb devices | awk 'NR > 1 && $2 == "device" { print $1 }'
)

device_count=${#devices[@]}

# Check whether any device is connected
if (( device_count == 0 )); then
    echo "No Android device is connected."
    exit 1
fi

# Display the main menu
echo "Select an action:"
echo "[0] Disconnect ports"
echo "[1] Connect ports"
echo "[2] List forwarded ports"

read -rp "Enter your choice (0/1/2): " main_action

case "$main_action" in
    0|1)
        ;;
    2)
        adb forward --list
        exit 0
        ;;
    *)
        echo "Invalid option."
        exit 1
        ;;
esac

# Display the connected devices
echo "Connected devices:"

for i in "${!devices[@]}"; do
    echo "[$i] ${devices[$i]}"
done

read -rp "Select a device (0-$((device_count - 1))): " device_index

# Validate the selected device
if ! [[ "$device_index" =~ ^[0-9]+$ ]] ||
    (( device_index < 0 || device_index >= device_count )); then
    echo "Invalid device selection."
    exit 1
fi

selected_device="${devices[$device_index]}"

echo "Selected device: $selected_device"

# Disconnect ports
if [[ "$main_action" == "0" ]]; then
    read -rp "Enter the ports to disconnect, separated by spaces: " -a ports

    if (( ${#ports[@]} == 0 )); then
        echo "No port was entered."
        exit 1
    fi

    for port in "${ports[@]}"; do
        if ! [[ "$port" =~ ^[0-9]+$ ]]; then
            echo "Invalid port: $port"
            exit 1
        fi
    done

    for port in "${ports[@]}"; do
        echo "Removing forward port tcp:$port..."
        adb -s "$selected_device" forward --remove "tcp:$port" 2>/dev/null || true

        echo "Removing reverse port tcp:$port..."
        adb -s "$selected_device" reverse --remove "tcp:$port" 2>/dev/null || true
    done

    echo "All selected ports have been disconnected."
    exit 0
fi

# Select the connection method
echo "Select the connection method:"
echo "[0] Forward port (device to host)"
echo "[1] Reverse port (host to device)"

read -rp "Enter your choice (0/1): " connection_method

if [[ "$connection_method" != "0" && "$connection_method" != "1" ]]; then
    echo "Invalid option."
    exit 1
fi

# Get the ports to forward or reverse
read -rp "Enter the ports, separated by spaces: " -a ports

if (( ${#ports[@]} == 0 )); then
    echo "No port was entered."
    exit 1
fi

# Validate the ports
for port in "${ports[@]}"; do
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "Invalid port: $port"
        exit 1
    fi
done

# Forward or reverse the selected ports
for port in "${ports[@]}"; do
    if [[ "$connection_method" == "0" ]]; then
        echo "Forwarding tcp:$port to tcp:$port..."
        adb -s "$selected_device" forward "tcp:$port" "tcp:$port"
    else
        echo "Reversing tcp:$port to tcp:$port..."
        adb -s "$selected_device" reverse "tcp:$port" "tcp:$port"
    fi
done

echo "All selected ports have been processed."

# Generated GTP 6 Astra Medium