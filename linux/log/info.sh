#!/usr/bin/env bash

LOGFILE="/tmp/logscript-uwu.log"
MAX_LINES=10000

# =========================
# MESSAGE MAP (EDIT HERE)
# =========================
get_message() {
    case "$1" in
        1) echo "f12 active" ;;
        2) echo "f12 inactive" ;;
        3) echo "VolUp and vol now = $(wpctl get-volume @DEFAULT_AUDIO_SINK@)" ;;
        4) echo "VolDown and vol now = $(wpctl get-volume @DEFAULT_AUDIO_SINK@)" ;;
        5) echo "Mute" ;;
        6) echo "Password Wrong" ;;
        *) echo "unknown code: $1" ;;
    esac
}

# =========================
# LOG FUNCTION
# =========================
log_message() {
    local code="$1"
    local message
    message="$(get_message "$code")"

    printf "%s [%s] %s\n" \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$code" \
        "$message" >> "$LOGFILE"
}

# =========================
# ROTATE LOG (KEEP 10000)
# =========================
rotate_log() {
    if [[ -f "$LOGFILE" ]]; then
        local lines
        lines=$(wc -l < "$LOGFILE")

        if (( lines > MAX_LINES )); then
            tail -n "$MAX_LINES" "$LOGFILE" > "${LOGFILE}.tmp"
            mv "${LOGFILE}.tmp" "$LOGFILE"
        fi
    fi
}

# =========================
# MAIN
# =========================
if [[ -z "$1" ]]; then
    echo "Usage: $0 <code>"
    exit 1
fi

log_message "$1"
rotate_log