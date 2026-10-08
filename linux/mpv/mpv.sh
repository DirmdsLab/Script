#!/usr/bin/env bash

# Check arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <video-file>"
    exit 1
fi

VIDEO="$1"

# Extract filename without path and extension
VIDEO_NAME=$(basename "$VIDEO")
VIDEO_NAME="${VIDEO_NAME%.*}"

# Keep only alphanumeric characters
VIDEO_NAME=$(echo "$VIDEO_NAME" | tr -cd '[:alnum:]')

# Use fallback name if empty
if [ -z "$VIDEO_NAME" ]; then
    VIDEO_NAME="default"
fi

# Generate a timestamp for a unique session name
TIMESTAMP=$(date +%s)

# Define session name
SESSION_NAME="MPV-${VIDEO_NAME}-${TIMESTAMP}"

# Launch mpv in a detached tmux session
tmux new-session -d -s "$SESSION_NAME" "mpv \"$VIDEO\""

echo "MPV started in tmux session: $SESSION_NAME"