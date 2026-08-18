#!/usr/bin/env bash

SCREENSHOT_DIR="$HOME/Pictures/Screenshot"
mkdir -p "$SCREENSHOT_DIR"

FILE="$SCREENSHOT_DIR/Screenshot-$(date +'%Y-%m-%d-%H%M%S').png"

case "$1" in
    fullss)
        if grim "$FILE" && [[ -s "$FILE" ]]; then
            notify-send "Screenshot Saved" "$(basename "$FILE")"
        else
            notify-send "Screenshot Failed"
        fi
        ;;

    cropss)
        if grim -g "$(slurp)" "$FILE" && [[ -s "$FILE" ]]; then
            notify-send "Screenshot Saved" "$(basename "$FILE")"
        else
            notify-send "Screenshot Failed"
        fi
        ;;

    *)
        echo "Usage: $0 {fullss|cropss}"
        exit 1
        ;;
esac