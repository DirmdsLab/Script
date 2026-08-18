#!/usr/bin/env bash

# Cek apakah file subtitle diberikan
if [ -z "$1" ]; then
  echo "Usage: $0 <subtitle_file.ext>"
  exit 1
fi

INPUT="$1"
BASENAME=$(basename "$INPUT")
FILENAME="${BASENAME%.*}"

echo "🎯 Pilih format output:"
echo "1) srt"
echo "2) ass"
echo "3) vtt"
echo "4) ttml"

read -p "Masukkan nomor format yang diinginkan: " CHOICE

case "$CHOICE" in
  1) EXT="srt" ;;
  2) EXT="ass" ;;
  3) EXT="vtt" ;;
  4) EXT="ttml" ;;
  *)
    echo "❌ Format tidak dikenal."
    exit 1
    ;;
esac

OUTPUT="${FILENAME}.${EXT}"

# Proses konversi
ffmpeg -y -i "$INPUT" "$OUTPUT"

echo "✅ Subtitle berhasil dikonversi ke: $OUTPUT"
