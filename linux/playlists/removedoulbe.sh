#!/usr/bin/env bash

set -euo pipefail

PLAYLIST="${1:-music.m3u}"
BACKUP="${PLAYLIST}.bak"
TEMP="${PLAYLIST}.tmp"

if [[ ! -f "$PLAYLIST" ]]; then
    echo "Error: playlist tidak ditemukan: $PLAYLIST"
    exit 1
fi

# Backup playlist asli
cp -f "$PLAYLIST" "$BACKUP"

awk '
BEGIN {
    # Path terakhir yang dibaca
    last_path = ""
}

# Baris komentar/metadata, tetap dipertahankan
/^#/ {
    print
    next
}

# Baris kosong, tetap dipertahankan
/^$/ {
    print
    next
}

{
    # Jika path sudah pernah muncul, jangan tampilkan lagi
    if (!seen[$0]++) {
        print
    }
}
' "$PLAYLIST" > "$TEMP"

# Ganti playlist asli dengan hasil
mv -f "$TEMP" "$PLAYLIST"

echo "Duplicate path removed."
echo "Clean playlist:"
echo "$PLAYLIST"
echo "Original playlist backed up to:"
echo "$BACKUP"