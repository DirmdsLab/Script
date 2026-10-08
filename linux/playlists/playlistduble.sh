#!/usr/bin/env bash

# Check arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 repeat_count input_playlist.m3u"
    exit 1
fi

COUNT="$1"
INPUT="$2"
OUTPUT="${INPUT%.m3u}_x${COUNT}.m3u"

# Validate COUNT as a positive integer
if ! [[ "$COUNT" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: repeat_count must be a positive integer (>0)"
    exit 1
fi

# Write playlist header
echo "#EXTM3U" > "$OUTPUT"

# Read each line and duplicate every EXTINF + path pair
prev=""

while IFS= read -r line; do
    if [[ "$line" == \#EXTINF* ]]; then
        prev="$line"
    elif [[ -n "$prev" ]]; then
        for ((i=0; i<COUNT; i++)); do
            echo "$prev" >> "$OUTPUT"
            echo "$line" >> "$OUTPUT"
        done
        prev=""
    fi
done < "$INPUT"

echo "Playlist entries successfully repeated $COUNT times: $OUTPUT"
