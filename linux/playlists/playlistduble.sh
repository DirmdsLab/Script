#!/usr/bin/env bash

# Cek argumen
if [ $# -ne 2 ]; then
    echo "Usage: $0 jumlah_penggandaan input_playlist.m3u"
    exit 1
fi

COUNT="$1"
INPUT="$2"
OUTPUT="${INPUT%.m3u}_x${COUNT}.m3u"

# Validasi COUNT harus angka positif
if ! [[ "$COUNT" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: jumlah_penggandaan harus angka positif (>0)"
    exit 1
fi

# Tulis header
echo "#EXTM3U" > "$OUTPUT"

# Baca file baris demi baris dan gandakan tiap pasangan EXTINF + path
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

echo "✅ Playlist berhasil digandakan $COUNT kali per entri: $OUTPUT"

