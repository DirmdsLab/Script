#!/usr/bin/env bash

set -u

WOFI_OPTIONS=(
    --dmenu
    --insensitive
    --cache-file
    /dev/null
    --width
    600
    --height
    450
)

# Show clipboard history
selected_item=$(
    cliphist list |
        wofi "${WOFI_OPTIONS[@]}" \
        --prompt "Clipboard History"
)

# Exit if no item is selected
[[ -z "$selected_item" ]] && exit 0

# Show action menu
action=$(
    printf '%s\n' \
        "Paste" \
        "Pin" \
        "Delete" |
        wofi "${WOFI_OPTIONS[@]}" \
        --prompt "Select Action"
)

# Process the selected action
case "$action" in
    "Paste")
        tmp=$(mktemp)
    
        cliphist decode <<< "$selected_item" > "$tmp"
    
        mime=$(file --mime-type -b "$tmp")
    
        case "$mime" in
            image/png|image/jpeg|image/webp)
                wl-copy --type "$mime" < "$tmp"
                ;;
            *)
                wl-copy < "$tmp"
                ;;
        esac
    
        rm "$tmp"
        ;;

    "Pin")
        cliphist pin <<< "$selected_item"
        ;;

    "Delete")
        cliphist delete <<< "$selected_item"
        ;;

    *)
        exit 0
        ;;
esac


# Generated GTP 6 Astra Medium