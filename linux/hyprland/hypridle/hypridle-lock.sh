#!/usr/bin/env bash

LOG_FILE="/tmp/lockscreenstyle.log"
LOCK_SCRIPT="$HOME/File/Script/hyprland/hyprlock/hyprlock-script.sh"
VIDEO="$HOME/Videos/Wallpaper/santai-hijau-lofi.mp4"

# Check if hyprlock is already running
if pgrep -x hyprlock > /dev/null; then
    echo "[LOG] Lockscreen is already active." >> "$LOG_FILE"
    exit 0
fi

# Check if the video file exists
if [[ -f "$VIDEO" ]]; then
    echo "[LOG] Video found: $VIDEO" >> "$LOG_FILE"
    "$LOCK_SCRIPT" videopath "$VIDEO"
else
    echo "[LOG] Video not found, falling back to hyprlock." >> "$LOG_FILE"
    hyprlock
fi