#!/usr/bin/env bash

# Cek apakah file diberikan
if [ -z "$1" ]; then
  echo "Usage: $0 <video_file.mkv>"
  exit 1
fi

FILE="$1"
BASENAME=$(basename "$FILE")
FILENAME="${BASENAME%.*}"  # tanpa ekstensi

# Tampilkan daftar subtitle
echo "📄 Daftar subtitle:"
ffprobe -v error \
  -select_streams s \
  -show_entries stream=index,codec_name:stream_tags=language \
  -of json "$FILE" | jq -r '
    .streams[] |
    "Subtitle #\(.index) - Codec: \(.codec_name) - Language: \(.tags.language // "unknown")"
  '

echo ""
read -p "Masukkan nomor subtitle yang ingin diekstrak (contoh: 13): " SUB_INDEX

# Ambil codec dan bahasa dari stream yang dipilih
STREAM_INFO=$(ffprobe -v error \
  -select_streams s \
  -show_entries stream=index,codec_name:stream_tags=language \
  -of json "$FILE" | jq -r \
  --argjson idx "$SUB_INDEX" '
    .streams[] | select(.index == $idx) |
    "\(.codec_name) \(.tags.language // "unknown")"
  ')

# Pisahkan info
CODEC=$(echo "$STREAM_INFO" | awk '{print $1}')
LANG=$(echo "$STREAM_INFO" | awk '{print $2}')

# Tentukan ekstensi berdasarkan codec
case "$CODEC" in
  ass) EXT="ass" ;;
  ssa) EXT="ssa" ;;
  subrip|srt) EXT="srt" ;;
  *) EXT="$CODEC" ;;  # fallback ke codec langsung
esac

# Nama file output: <nama_video>-<index>-<lang>.<ext>
OUTFILE="${FILENAME}-${SUB_INDEX}-${LANG}.${EXT}"

# Ekstrak subtitle
ffmpeg -y -i "$FILE" -map 0:$SUB_INDEX "$OUTFILE"

echo "✅ Subtitle stream #$SUB_INDEX berhasil diekstrak ke: $OUTFILE"
