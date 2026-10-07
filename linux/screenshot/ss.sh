#!/usr/bin/env bash

SCREENSHOT_DIR="$HOME/Pictures/Screenshot"
mkdir -p "$SCREENSHOT_DIR"

FILE="$SCREENSHOT_DIR/Screenshot-$(date +'%Y-%m-%d-%H%M%S').png"


copy_to_clipboard() {
    if wl-copy --type image/png < "$FILE"; then
        notify-send "Screenshot Copied" "PNG ready in clipboard"
    else
        notify-send "Clipboard Failed"
    fi
}


save_success() {
    if [[ -s "$FILE" ]]; then
        
        # kirim PNG ke clipboard
        copy_to_clipboard

        notify-send "Screenshot Saved" "$(basename "$FILE")"
    else
        notify-send "Screenshot Failed"
        exit 1
    fi
}


case "$1" in

    fullss)
        if grim "$FILE"; then
            save_success
        fi
        ;;


    cropss)
        AREA=$(slurp)

        [[ -z "$AREA" ]] && exit 0

        if grim -g "$AREA" "$FILE"; then
            save_success
        fi
        ;;


    *)
        echo "Usage: $0 {fullss|cropss}"
        exit 1
        ;;

esac

