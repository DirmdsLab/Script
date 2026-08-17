#!/usr/bin/env bash

ACTIVE_WIN=$(hyprctl activewindow -j)

if [ -z "$ACTIVE_WIN" ] || [ "$ACTIVE_WIN" = "null" ]; then
    notify-send "Hyprland" "Tidak ada window aktif"
    exit 1
fi

WIN_CLASS=$(echo "$ACTIVE_WIN" | jq -r '.class')
WIN_TITLE=$(echo "$ACTIVE_WIN" | jq -r '.title')

WIN_CLASS_ESCAPED=$(printf '%s' "$WIN_CLASS" | sed 's/\\/\\\\/g; s/"/\\"/g')
WIN_TITLE_ESCAPED=$(printf '%s' "$WIN_TITLE" | sed 's/\\/\\\\/g; s/"/\\"/g')

echo "Window aktif:"
echo "Class : $WIN_CLASS"
echo "Title : $WIN_TITLE"

OPTIONS="1\n0.95\n0.9\n0.8\n0.7\n0.5\n0.3\n0.2\n0.1"

CHOICE=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Pilih opacity")

[ -z "$CHOICE" ] && exit 0

TITLE_OPTION=$(echo -e "Class + Title\nClass saja" | wofi --dmenu --prompt "Target rule")

[ -z "$TITLE_OPTION" ] && exit 0

if [ "$TITLE_OPTION" = "Class + Title" ]; then
    LUA_RULE="hl.window_rule({match = {class = \"$WIN_CLASS_ESCAPED\", title = \"$WIN_TITLE_ESCAPED\"}, opacity = \"$CHOICE override\"})"
else
    LUA_RULE="hl.window_rule({match = {class = \"$WIN_CLASS_ESCAPED\"}, opacity = \"$CHOICE override\"})"
fi

echo "Apply rule:"
echo "$LUA_RULE"

hyprctl eval "$LUA_RULE"