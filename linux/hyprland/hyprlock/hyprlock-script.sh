#!/usr/bin/env bash

PID_FILE="/tmp/wallpaper.pid"
MONITOR="DP-1"
VIDEO_DIR="$HOME/Videos/Wallpaper"

# Cek apakah dipanggil dengan argumen
if [[ "$1" == "videopath" && -n "$2" ]]; then
    VIDEO="$2"
    SKIP_EFFECTS=true
else
# Cari semua file video di folder
mapfile -t FILES < <(find -L "$VIDEO_DIR" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.m3u" \) -printf '%T@ %p\n' \
    | sort -nr | cut -d' ' -f2-)

# Buat daftar untuk wofi: hanya nama file + icon 🎬
MENU=$(for f in "${FILES[@]}"; do
    name=$(basename "$f")
    echo "🎬 $name"
done | wofi --dmenu --insensitive --prompt "Pilih Video Wallpaper:")

# Kalau tidak memilih apa pun, keluar
[ -z "$MENU" ] && exit 0

# Cari path asli dari nama yang dipilih
VIDEO=""
for f in "${FILES[@]}"; do
    if [[ "🎬 $(basename "$f")" == "$MENU" ]]; then
        VIDEO="$f"
        break
    fi
done

SKIP_EFFECTS=false


fi



# Kalau tidak memilih apa pun, keluar
[ -z "$VIDEO" ] && exit 0

MPV_OPTS='--title=mpvpaperhyprlock --no-config volume=100 --loop --loop-playlist shuffle --vf=scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080'



if [ "$SKIP_EFFECTS" = false ]; then
    MIRROR=$(printf "🎚️ Tidak\n🌈 Color Up\n🪞 Mirror Horizontal\n🔇 Mute\n🔇🪞 Mute Miror\n🚫🎶 Tanpa Audio Visual" | wofi --dmenu --prompt "Efek")

    [ "$MIRROR" = "🌈 Color Up" ] && MPV_OPTS="$MPV_OPTS input-ipc-server=/tmp/mpvlock-socket"
    [ "$MIRROR" = "🪞 Mirror Horizontal" ] && MPV_OPTS="$MPV_OPTS,hflip"
    [ "$MIRROR" = "🔇 Mute" ] && MPV_OPTS="mute=yes,$MPV_OPTS"
    [ "$MIRROR" = "🔇🪞 Mute Miror" ] && MPV_OPTS="mute=yes,$MPV_OPTS,hflip"
    [ "$MIRROR" = "🚫🎶 Tanpa Audio Visual" ] && NO_AUDIO_VISUAL=true
fi


# Hentikan wallpaper lama jika ada
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill "$OLD_PID" 2>/dev/null; then
        rm "$PID_FILE"
    fi
fi

hyprctl monitors -j | jq -e '.[] | select(.specialWorkspace.name=="special:magic" and .specialWorkspace.id!=-1)' >/dev/null && hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("magic"))' 
hyprctl monitors -j | jq -e '.[] | select(.specialWorkspace.name=="special:temp" and .specialWorkspace.id!=-1)' >/dev/null && hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("temp"))' 
hyprctl monitors -j | jq -e '.[] | select(.specialWorkspace.name=="special:UwU" and .specialWorkspace.id!=-1)' >/dev/null && hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("UwU"))' 
hyprctl monitors -j | jq -e '.[] | select(.specialWorkspace.name=="special:Hmph" and .specialWorkspace.id!=-1)' >/dev/null && hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("Hmph"))' 
hyprctl monitors -j | jq -e '.[] | select(.specialWorkspace.name=="special:sysmon" and .specialWorkspace.id!=-1)' >/dev/null && hyprctl eval 'hl.dispatch(hl.dsp.workspace.toggle_special("sysmon"))' 


sleep 0.5

hyprctl dispatch "hl.dsp.focus({ workspace = 21 })"

mpvpaper -o "$MPV_OPTS" "$MONITOR" "$VIDEO" -f &

# Tunggu proses mpv muncul lalu simpan PID-nya
sleep 0.5
PID=$(pgrep -f "mpv.*mpvpaperhyprlock" | head -n 1)
echo "$PID" > "$PID_FILE"

: > /tmp/lockscreenstyle.log


sleep 0.5
echo '{ "command": ["set_property", "saturation", 70] }' | socat - /tmp/mpvlock-socket

sleep 0.5

kitty --class kitty-overlay \
  --config "$HOME/File/Software/App/kitty/kitty-log.conf" \
  -e sh -c '
    sleep 1
    logfile="/tmp/lockscreenstyle.log"
    sleep 1
    # 1: print baris per baris dengan delay
    while IFS= read -r line; do
      printf "%s\n" "$line"
      sleep 0.2
    done < "$logfile"

    # 2: lanjut follow seperti tail -f
    tail -f "$logfile"
  ' &


KITTY_OVERLAY_PID=$!

sleep 0.5

hyprctl dispatch 'hl.dsp.focus({ window = "class:kitty-overlay" })'

sleep 0.5

if [ "$NO_AUDIO_VISUAL" != true ]; then
    kitty --class kitty-audio --config "$HOME/File/Software/App/kitty/kitty-transparant.conf" -e cava -p "$HOME/File/Software/App/cava/kitty-audio-config" &
    KITTY_AUDIO_PID=$!
fi

stdbuf -oL -eL hyprlock >> /tmp/lockscreenstyle.log 2>&1 &

# Simpan PID hyprlock
HYPRLOCK_PID=$!

wait $HYPRLOCK_PID

kill "$KITTY_AUDIO_PID" 2>/dev/null
kill "$KITTY_OVERLAY_PID" 2>/dev/null

if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm "$PID_FILE"
fi


hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = "empty" }))'