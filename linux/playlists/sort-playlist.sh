#!/usr/bin/env bash

set -euo pipefail

# Check argument
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 file.m3u"
    exit 1
fi

INPUT_FILE="$1"

# Check file exists
if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: File not found: $INPUT_FILE"
    exit 1
fi

# Get file info
DIR_NAME="$(dirname "$INPUT_FILE")"
BASE_NAME="$(basename "$INPUT_FILE" .m3u)"
OUTPUT_FILE="${DIR_NAME}/${BASE_NAME}-sort.m3u"

# Temporary file
TEMP_FILE="$(mktemp)"

# Read playlist and sort by modification time
while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # Check file exists
    if [[ -f "$line" ]]; then
        MOD_TIME="$(stat -c %Y "$line" 2>/dev/null || stat -f %m "$line")"
        echo "${MOD_TIME}|${line}" >> "$TEMP_FILE"
    fi
done < "$INPUT_FILE"

# Create sorted playlist
sort -nr "$TEMP_FILE" | cut -d'|' -f2- > "$OUTPUT_FILE"

# Cleanup
rm -f "$TEMP_FILE"

echo "Sorted playlist created:"
echo "$OUTPUT_FILE"

#addon
# Backup original playlist
mv "$INPUT_FILE" "${INPUT_FILE}.bak"

# Replace original playlist with sorted version
mv "$OUTPUT_FILE" "$INPUT_FILE"

echo "Original playlist backed up to:"
echo "${INPUT_FILE}.bak"

echo "Sorted playlist installed as:"
echo "$INPUT_FILE"