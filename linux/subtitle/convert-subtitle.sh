#!/usr/bin/env bash

# Check if a subtitle file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <subtitle_file.ext>"
    exit 1
fi

INPUT="$1"
BASENAME=$(basename "$INPUT")
FILENAME="${BASENAME%.*}"

echo "Select output format:"
echo "1) srt"
echo "2) ass"
echo "3) vtt"
echo "4) ttml"

read -p "Enter the desired format number: " CHOICE

case "$CHOICE" in
    1) EXT="srt" ;;
    2) EXT="ass" ;;
    3) EXT="vtt" ;;
    4) EXT="ttml" ;;
    *)
        echo "Error: Unknown format."
        exit 1
        ;;
esac

OUTPUT="${FILENAME}.${EXT}"

# Convert subtitle file
ffmpeg -y -i "$INPUT" "$OUTPUT"

echo "Subtitle successfully converted to: $OUTPUT"
