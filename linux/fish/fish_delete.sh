#!/usr/bin/env fish

# ==========================================
# Delete recent Fish history
#
# Usage:
#   ./fish_delete.sh 10
#   ./fish_delete.sh 20
# ==========================================

if test (count $argv) -ne 1
    echo "Usage: $argv[1] <minutes>"
    echo "Example:"
    echo "  $argv[1] 10"
    echo "  $argv[1] 20"
    exit 1
end

set minutes $argv[1]

# Pastikan angka
if not string match -qr '^[0-9]+$' -- $minutes
    echo "Error: minutes harus berupa angka."
    exit 1
end

# Lokasi Fish history
if set -q XDG_DATA_HOME
    set history_file "$XDG_DATA_HOME/fish/fish_history"
else
    set history_file "$HOME/.local/share/fish/fish_history"
end

if not test -f "$history_file"
    echo "Error: history tidak ditemukan:"
    echo "$history_file"
    exit 1
end

# Waktu sekarang
set now (date +%s)

# Batas waktu
set cutoff (math "$now - ($minutes * 60)")

set cutoff_date (date -d "@$cutoff" "+%Y-%m-%d %H:%M:%S")
set now_date (date "+%Y-%m-%d %H:%M:%S")

echo ""
echo "=========================================="
echo "        FISH HISTORY DELETE"
echo "=========================================="
echo ""
echo "History file : $history_file"
echo ""
echo "Sekarang     : $now_date"
echo "Hapus sejak  : $cutoff_date"
echo "Durasi       : $minutes menit terakhir"
echo ""
echo "PERINGATAN:"
echo "Semua history dalam rentang tersebut"
echo "akan dihapus dan TIDAK dibuat backup."
echo ""

read -P "Lanjutkan hapus? [y/N] " confirm

switch $confirm
    case y Y yes YES Yes
        echo ""
        echo "Menghapus history..."

    case '*'
        echo ""
        echo "Dibatalkan. Tidak ada perubahan."
        exit 0
end

set temp_file (mktemp)

# Proses fish_history
awk -v cutoff="$cutoff" '
/^-/ {
    if (entry_time >= cutoff) {
        skip = 1
    } else {
        skip = 0
    }

    entry_time = 0
}

/^  when:/ {
    entry_time = $2
}

{
    if (!skip) {
        print
    }
}
' "$history_file" > "$temp_file"

if test $status -ne 0
    echo "Error: gagal memproses history."
    rm -f "$temp_file"
    exit 1
end

mv "$temp_file" "$history_file"

if test $status -ne 0
    echo "Error: gagal mengganti history."
    exit 1
end

# Refresh Fish history
history merge

echo ""
echo "Selesai."
echo "History $minutes menit terakhir telah dihapus."