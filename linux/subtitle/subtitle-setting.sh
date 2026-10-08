#!/usr/bin/env bash

set -euo pipefail

# Display an error message and exit
die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

# Validate arguments
if [[ $# -ne 1 ]]; then
    printf 'Usage: %s <video_file.mkv>\n' "$0"
    exit 1
fi

INPUT="$1"
BASENAME="${INPUT##*/}"
FILENAME="${BASENAME%.*}"

[[ -f "$INPUT" ]] || die "File not found: $INPUT"

# Check dependencies
for cmd in ffprobe ffmpeg jq; do
    command -v "$cmd" >/dev/null 2>&1 ||
        die "Required command not found: $cmd"
done

# Enable colors when running in a terminal
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    BOLD=$'\033[1m'
    CYAN=$'\033[36m'
    RESET=$'\033[0m'
else
    BOLD=""
    CYAN=""
    RESET=""
fi

# Retrieve subtitle stream metadata
if ! PROBE_JSON=$(ffprobe -v error \
    -select_streams s \
    -show_entries stream=index,codec_name:stream_tags=language \
    -of json \
    -i "$INPUT"); then
    die "Failed to read subtitle streams."
fi

STREAM_DATA=$(jq -r '
    .streams[] |
    [
        (.index | tostring),
        (.codec_name // "unknown"),
        (.tags.language // "unknown")
    ] | @tsv
' <<< "$PROBE_JSON")

[[ -n "$STREAM_DATA" ]] ||
    die "No subtitle streams found."

# Store subtitle metadata
declare -a STREAM_INDEXES=()
declare -A STREAM_CODECS=()
declare -A STREAM_LANGUAGES=()

INDEX_WIDTH=5
CODEC_WIDTH=5
LANG_WIDTH=8

while IFS=$'\t' read -r index codec language; do
    STREAM_INDEXES+=("$index")
    STREAM_CODECS["$index"]="$codec"
    STREAM_LANGUAGES["$index"]="$language"

    (( ${#index} > INDEX_WIDTH )) &&
        INDEX_WIDTH=${#index}

    (( ${#codec} > CODEC_WIDTH )) &&
        CODEC_WIDTH=${#codec}

    (( ${#language} > LANG_WIDTH )) &&
        LANG_WIDTH=${#language}

done <<< "$STREAM_DATA"

# Print a horizontal table segment
print_line() {
    local width="$1"
    local padding

    printf -v padding '%*s' "$((width + 2))" ''
    printf '%s' "${padding// /─}"
}

# Print a table border
print_border() {
    local left="$1"
    local middle="$2"
    local right="$3"

    printf '%s' "$left"
    print_line "$INDEX_WIDTH"

    printf '%s' "$middle"
    print_line "$CODEC_WIDTH"

    printf '%s' "$middle"
    print_line "$LANG_WIDTH"

    printf '%s\n' "$right"
}

# Print a table row
print_row() {
    printf '│ %-*s │ %-*s │ %-*s │\n' \
        "$INDEX_WIDTH" "$1" \
        "$CODEC_WIDTH" "$2" \
        "$LANG_WIDTH" "$3"
}

# Display subtitle table
printf '\n%s%sAvailable Subtitle Streams%s\n\n' \
    "$BOLD" "$CYAN" "$RESET"

printf '%s' "$CYAN"

print_border "┌" "┬" "┐"
print_row "Index" "Codec" "Language"
print_border "├" "┼" "┤"

printf '%s' "$RESET"

for index in "${STREAM_INDEXES[@]}"; do
    print_row \
        "$index" \
        "${STREAM_CODECS[$index]}" \
        "${STREAM_LANGUAGES[$index]}"
done

printf '%s' "$CYAN"
print_border "└" "┴" "┘"
printf '%s' "$RESET"

# Select subtitle stream
printf '\n'
read -r -p "Enter subtitle stream index: " SUB_INDEX

[[ "$SUB_INDEX" =~ ^[0-9]+$ ]] ||
    die "Invalid stream index."

[[ -v STREAM_CODECS[$SUB_INDEX] ]] ||
    die "Subtitle stream not found: $SUB_INDEX"

CODEC="${STREAM_CODECS[$SUB_INDEX]}"
LANG="${STREAM_LANGUAGES[$SUB_INDEX]}"

# Determine output extension
case "$CODEC" in
    ass)        EXT="ass" ;;
    ssa)        EXT="ssa" ;;
    subrip|srt) EXT="srt" ;;
    *)          EXT="$CODEC" ;;
esac

# Generate output filename
OUTFILE="${FILENAME}-${SUB_INDEX}-${LANG}.${EXT}"

# Display extraction details
printf '\n%sExtraction Details%s\n' "$BOLD" "$RESET"
printf '  Stream   : %s\n' "$SUB_INDEX"
printf '  Codec    : %s\n' "$CODEC"
printf '  Language : %s\n' "$LANG"
printf '  Output   : %s\n\n' "$OUTFILE"

# Extract selected subtitle stream
ffmpeg -y -i "$INPUT" -map "0:$SUB_INDEX" "$OUTFILE"

printf '\n%sSubtitle extracted successfully%s\n' \
    "$BOLD" "$RESET"

printf 'Output: %s\n' "$OUTFILE"
