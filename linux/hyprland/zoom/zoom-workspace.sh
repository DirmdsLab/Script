#!/usr/bin/env bash

ACTION="$1"

get_current() {
    hyprctl getoption cursor:zoom_factor -j | jq -r '.float'
}

set_zoom() {
    hyprctl eval "hl.config({ cursor = { zoom_factor = $1 } })"
}

case "$ACTION" in
    zoomin)
        CURRENT=$(get_current)
        NEXT=$(awk -v c="$CURRENT" 'BEGIN {
            c += 0.5
            if (c > 5) c = 5
            print c
        }')
        set_zoom "$NEXT"
        ;;

    zoomout)
        CURRENT=$(get_current)
        NEXT=$(awk -v c="$CURRENT" 'BEGIN {
            c -= 0.5
            if (c < 1) c = 1
            print c
        }')
        set_zoom "$NEXT"
        ;;

    zoomreset)
        set_zoom 1
        ;;

    *)
        echo "Usage: $0 {zoomin|zoomout|zoomreset}"
        exit 1
        ;;
esac