#!/usr/bin/env bash

set -euo pipefail

PLAYLIST="${1:-music.m3u}"
BACKUP="${PLAYLIST}.bak"
TEMP="${PLAYLIST}.tmp"

if [[ ! -f "$PLAYLIST" ]]; then
    echo "Error: Playlist not found: $PLAYLIST"
    exit 1
fi

# Back up the original playlist
cp -f "$PLAYLIST" "$BACKUP"

awk '
BEGIN {
    # Last path read
    last_path = ""
}

# Preserve comment and metadata lines
/^#/ {
    print
    next
}

# Preserve empty lines
/^$/ {
    print
    next
}

{
    # Skip paths that have already appeared
    if (!seen[$0]++) {
        print
    }
}
' "$PLAYLIST" > "$TEMP"

# Replace the original playlist with the cleaned version
mv -f "$TEMP" "$PLAYLIST"

echo "Duplicate paths removed."
echo "Clean playlist:"
echo "$PLAYLIST"
echo "Original playlist backed up to:"
echo "$BACKUP"