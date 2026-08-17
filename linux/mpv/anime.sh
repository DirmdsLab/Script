#!/usr/bin/env bash

set -euo pipefail

# ==========================
# Cek argumen
# ==========================
if [ $# -eq 0 ]; then
    echo "Usage: $0 <video-file>"
    exit 1
fi

VIDEO="$1"

# ==========================
# Direktori script
# ==========================
CAVA_CONFIG="$HOME/File/Software/App/cava/cava-anime.conf"

if [ ! -f "$CAVA_CONFIG" ]; then
    echo "Config cava tidak ditemukan:"
    echo "  $CAVA_CONFIG"
    exit 1
fi

# ==========================
# Nama session
# ==========================
VIDEO_NAME=$(basename "$VIDEO")
VIDEO_NAME="${VIDEO_NAME%.*}"
VIDEO_NAME=$(printf "%s" "$VIDEO_NAME" | tr -cd '[:alnum:]')

[ -z "$VIDEO_NAME" ] && VIDEO_NAME="default"

SESSION_NAME="ANIME-${VIDEO_NAME}-$(date +%s)"

# ==========================
# Pane kiri (mpv)
# ==========================
tmux new-session -d -s "$SESSION_NAME" \
    "mpv \"$VIDEO\"; tmux wait-for -S ${SESSION_NAME}_done"

# ==========================
# Pane kanan (25%)
# ==========================
tmux split-window -h -p 25 -t "$SESSION_NAME":0

# ==========================
# Bagi pane kanan
# Atas 35% (clock)
# Bawah 65% (cava)
# ==========================
tmux split-window -v -p 65 -t "$SESSION_NAME":0.1

# ==========================
# Jalankan peaclock
# ==========================
tmux send-keys -t "$SESSION_NAME":0.1 \
"clear; peaclock" C-m

# ==========================
# Jalankan cava
# ==========================
tmux send-keys -t "$SESSION_NAME":0.2 \
"clear; cava -p \"$CAVA_CONFIG\"" C-m

# focus to mpv
tmux select-pane -t "$SESSION_NAME":0.0

# ==========================
# Tutup session saat mpv selesai
# ==========================
(
    tmux wait-for "${SESSION_NAME}_done"
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null
) >/dev/null 2>&1 &

echo "Anime started in tmux session: $SESSION_NAME"

