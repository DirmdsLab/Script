#!/usr/bin/env bash

# Cek argumen
if [ $# -eq 0 ]; then
    echo "Usage: $0 <video-file>"
    exit 1
fi

VIDEO="$1"

# Ambil nama file tanpa path dan tanpa ekstensi
VIDEO_NAME=$(basename "$VIDEO")
VIDEO_NAME="${VIDEO_NAME%.*}"

# Sisakan hanya A-Z, a-z, dan 0-9
VIDEO_NAME=$(echo "$VIDEO_NAME" | tr -cd '[:alnum:]')

# Fallback jika kosong
if [ -z "$VIDEO_NAME" ]; then
    VIDEO_NAME="default"
fi

# Timestamp agar selalu unik
TIMESTAMP=$(date +%s)

# Nama session
SESSION_NAME="MPV-${VIDEO_NAME}-${TIMESTAMP}"

# Jalankan mpv di tmux
tmux new-session -d -s "$SESSION_NAME" "mpv \"$VIDEO\""

echo "MPV started in tmux session: $SESSION_NAME"