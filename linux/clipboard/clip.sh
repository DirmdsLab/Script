#!/usr/bin/env bash

# deps: cliphist wofi wl-copy

ACTION=$(printf "Paste\nDelete item\nDelete all" | \
  wofi --dmenu --prompt "Clipboard")

case "$ACTION" in
  "Paste")
    ITEM=$(cliphist list | \
      wofi --dmenu --prompt "Paste from history")

    [ -z "$ITEM" ] && exit 0
    cliphist decode <<< "$ITEM" | wl-copy
    ;;

  "Delete item")
    ITEM=$(cliphist list | \
      wofi --dmenu --prompt "Delete from history")

    [ -z "$ITEM" ] && exit 0
    cliphist delete <<< "$ITEM"
    ;;

  "Delete all")
    printf "No\nYes" | \
      wofi --dmenu --prompt "Delete all clipboard history?" | \
      grep -q "Yes" || exit 0

    cliphist wipe
    ;;
esac
