#!/usr/bin/env bash

LOG="/tmp/lockscreenstyle.log"

echo "[INFO] $(date "+%F %T") Lock Idle..." >> "$LOG"

notify-send -t 1000 "lock idle"

sleep 2

echo "[INFO] $(date "+%F %T") Starting hyprlock..." >> "$LOG"

# Record lock start time
LOCK_START=$(date +%s)

hyprlock --config ~/File/Software/App/hyprland/hyprlock/hyprlock-idle.conf >>"$LOG" 2>&1
STATUS=$?

# Calculate lock duration
LOCK_END=$(date +%s)
LOCK_DURATION=$((LOCK_END - LOCK_START))

# Format duration as HH:MM:SS
HOURS=$((LOCK_DURATION / 3600))
MINUTES=$(((LOCK_DURATION % 3600) / 60))
SECONDS=$((LOCK_DURATION % 60))
LOCK_DURATION_FMT=$(printf "%02d:%02d:%02d" "$HOURS" "$MINUTES" "$SECONDS")

echo "[INFO] $(date "+%F %T") hyprlock exited with status $STATUS" >> "$LOG"
echo "[INFO] $(date "+%F %T") Lock duration: ${LOCK_DURATION_FMT} (${LOCK_DURATION}s)" >> "$LOG"

notify-send "unlock" "Lock duration: ${LOCK_DURATION_FMT}"