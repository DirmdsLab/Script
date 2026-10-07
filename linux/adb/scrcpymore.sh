#!/usr/bin/env bash

# Get the list of connected Android devices
mapfile -t devices < <(
    adb devices | awk 'NR > 1 && $2 == "device" { print $1 }'
)

device_count=${#devices[@]}

# Exit if no device is connected
if (( device_count == 0 )); then
    echo "No Android device is connected."
    exit 1
fi

# Ask the user to select a device if multiple devices are connected
if (( device_count > 1 )); then
    echo "Multiple Android devices detected:"

    for i in "${!devices[@]}"; do
        echo "$((i + 1)). ${devices[$i]}"
    done

    read -rp "Select a device number (1-${device_count}): " choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
        (( choice < 1 || choice > device_count )); then
        echo "Invalid device selection."
        exit 1
    fi

    selected_device="${devices[$((choice - 1))]}"
else
    selected_device="${devices[0]}"
fi

# Store the selected device option as an array
serial_option=(-s "$selected_device")

# Select the scrcpy mode
case "${1:-}" in
    novideo)
        shift
        scrcpy \
            "${serial_option[@]}" \
            --no-video \
            --window-title="Mini Desktop" \
            --disable-screensaver \
            "$@"
        ;;

    novirtual)
        shift
        scrcpy \
            "${serial_option[@]}" \
            --stay-awake \
            --window-title="Mini Desktop" \
            --disable-screensaver \
            "$@"
        ;;

    justinput)
        shift
        scrcpy \
            "${serial_option[@]}" \
            --no-video \
            --no-audio \
            --stay-awake \
            --window-title="Mini Desktop" \
            --disable-screensaver \
            --keyboard=uhid \
            --mouse=uhid \
            "$@"
        ;;

    inputandaudio)
        shift
        scrcpy \
            "${serial_option[@]}" \
            --no-video \
            --stay-awake \
            --window-title="Input And Audio" \
            --disable-screensaver \
            --keyboard=uhid \
            --mouse=uhid \
            "$@"
        ;;

    *)
        scrcpy \
            "${serial_option[@]}" \
            --new-display=1920x1080 \
            --stay-awake \
            --window-title="Mini Desktop" \
            --disable-screensaver \
            --window-width=1280 \
            "$@"
        ;;
esac


# Generated GTP 6 Astra Medium