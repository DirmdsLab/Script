#!/usr/bin/env bash

PID_FILE="/tmp/wallpaper.pid"
MONITOR="DP-1"
VIDEO_DIR="$HOME/Videos/Wallpapers"

VIDEO=""
SKIP_EFFECTS=false
NO_AUDIO_VISUAL=false
USE_IPC=false
USE_MIRROR=false


# Check direct video path argument
if [[ "$1" == "videopath" && -n "$2" ]]; then

    VIDEO="$2"
    SKIP_EFFECTS=true

else

    # Find video wallpapers
    mapfile -t FILES < <(
        find -L "$VIDEO_DIR" \
            -type f \
            \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.m3u" \) \
            -printf '%T@ %p\n' |
        sort -nr |
        cut -d' ' -f2-
    )


    # Video selector
    MENU=$(
        for f in "${FILES[@]}"; do
            basename "$f"
        done |
        wofi \
            --dmenu \
            --insensitive \
            --prompt "Select Video Wallpaper"
    )


    [ -z "$MENU" ] && exit 0


    # Resolve video path
    for f in "${FILES[@]}"; do

        if [[ "$(basename "$f")" == "$MENU" ]]; then
            VIDEO="$f"
            break
        fi

    done

fi


[ -z "$VIDEO" ] && exit 0


# ==========================================
# Symlink Video Cache
# ==========================================

TMP_DIR="/tmp/hyprlock-mpv_tmp"

# Create cache directory
mkdir -p -- "$TMP_DIR" || exit 1

# Delete cached files older than 7 days
find "$TMP_DIR" \
    -maxdepth 1 \
    -type f \
    -mmin +10080 \
    -delete


# Only cache symlink videos
if [[ -L "$VIDEO" ]]; then

    CACHE_VIDEO="$TMP_DIR/$(basename -- "$VIDEO")"

    # Copy only if not already cached
    if [[ ! -f "$CACHE_VIDEO" ]]; then

        notify-send "Copying to tmp"

        echo "Caching symlink video: $VIDEO"

        # Copy atomically to avoid incomplete cache
        TMP_COPY=$(mktemp "$TMP_DIR/.copy.XXXXXXXX") || exit 1

        if ! cp -- "$VIDEO" "$TMP_COPY"; then
            rm -f -- "$TMP_COPY"
            exit 1
        fi

        if ! mv -- "$TMP_COPY" "$CACHE_VIDEO"; then
            rm -f -- "$TMP_COPY"
            exit 1
        fi

    else

        echo "Using cached video: $CACHE_VIDEO"

    fi

    # Play cached video instead of symlink
    VIDEO="$CACHE_VIDEO"

fi


# Base mpv options


# Base mpv options
MPV_OPTS='--title=mpvpaperhyprlock --no-config volume=100 --loop --loop-playlist shuffle'


# Video filter
VIDEO_FILTER="scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,fps=60"



# Effect selector
if [ "$SKIP_EFFECTS" = false ]; then


    EFFECT_LIST=(
        "Color Up"
        "Mirror Horizontal"
        "Mute"
        "Disable Audio Visual"
    )


    SELECTED_EFFECTS=()


    while true; do


        MENU="None\n"


        for effect in "${EFFECT_LIST[@]}"; do

            CHECK="[ ]"


            for selected in "${SELECTED_EFFECTS[@]}"; do

                if [[ "$selected" == "$effect" ]]; then
                    CHECK="[x]"
                    break
                fi

            done


            MENU+="$CHECK $effect\n"

        done


        MENU+="Apply"


        CHOICE=$(printf "%b" "$MENU" |
            wofi \
            --dmenu \
            --prompt "Select Effects")


        [ -z "$CHOICE" ] && break



        EFFECT=$(echo "$CHOICE" | sed 's/^\[[ x]\] //')


        case "$EFFECT" in


            "None")

                SELECTED_EFFECTS=()
                break

                ;;


            "Apply")

                break

                ;;


            *)

                FOUND=false
                NEW_SELECTION=()


                for selected in "${SELECTED_EFFECTS[@]}"; do

                    if [[ "$selected" == "$EFFECT" ]]; then

                        FOUND=true

                    else

                        NEW_SELECTION+=("$selected")

                    fi

                done


                if [ "$FOUND" = false ]; then
                    NEW_SELECTION+=("$EFFECT")
                fi


                SELECTED_EFFECTS=("${NEW_SELECTION[@]}")

                ;;

        esac


    done



    # Apply effects
    for EFFECT in "${SELECTED_EFFECTS[@]}"; do


        case "$EFFECT" in


            "Color Up")

                MPV_OPTS="$MPV_OPTS --input-ipc-server=/tmp/mpvlock-socket"
                USE_IPC=true

                ;;


            "Mirror Horizontal")

                USE_MIRROR=true

                ;;


            "Mute")

                MPV_OPTS="$MPV_OPTS --mute=yes"

                ;;


            "Disable Audio Visual")

                NO_AUDIO_VISUAL=true

                ;;


        esac


    done


fi



# Add mirror filter
if [ "$USE_MIRROR" = true ]; then

    VIDEO_FILTER="$VIDEO_FILTER,hflip"

fi



# Add final video filter
MPV_OPTS="$MPV_OPTS --vf=$VIDEO_FILTER"



# Stop previous wallpaper
if [ -f "$PID_FILE" ]; then

    OLD_PID=$(cat "$PID_FILE")

    kill "$OLD_PID" 2>/dev/null

    rm "$PID_FILE"

fi



# Close special workspaces
for workspace in magic temp UwU Hmph sysmon; do

    hyprctl monitors -j |
    jq -e ".[] | select(.specialWorkspace.name==\"special:$workspace\" and .specialWorkspace.id!=-1)" \
    >/dev/null &&
    hyprctl eval "hl.dispatch(hl.dsp.workspace.toggle_special(\"$workspace\"))"

done



sleep 0.5



hyprctl dispatch "hl.dsp.focus({ workspace = 21 })"



# Remove old IPC socket
rm -f /tmp/mpvlock-socket



# Start wallpaper
mpvpaper -o "$MPV_OPTS" "$MONITOR" "$VIDEO" -f &



sleep 0.5


PID=$(pgrep -f "mpv.*mpvpaperhyprlock" | head -n 1)

echo "$PID" > "$PID_FILE"



: > /tmp/lockscreenstyle.log



# Apply saturation if IPC enabled
if [ "$USE_IPC" = true ]; then

    sleep 0.5


    if [ -S /tmp/mpvlock-socket ]; then

        echo '{ "command": ["set_property", "saturation", 70] }' |
        socat - /tmp/mpvlock-socket

    fi

fi



# Kitty overlay
sleep 0.5


kitty \
    --class kitty-overlay \
    --config "$HOME/File/Software/App/kitty/kitty-log.conf" \
    -e sh -c '
        sleep 1

        logfile="/tmp/lockscreenstyle.log"

        while IFS= read -r line; do
            printf "%s\n" "$line"
            sleep 0.2
        done < "$logfile"

        tail -f "$logfile"
    ' &


KITTY_OVERLAY_PID=$!



sleep 0.5



hyprctl dispatch 'hl.dsp.focus({ window = "class:kitty-overlay" })'



sleep 0.5



# Start cava
if [ "$NO_AUDIO_VISUAL" != true ]; then

    kitty \
        --class kitty-audio \
        --config "$HOME/File/Software/App/kitty/kitty-transparant.conf" \
        -e cava \
        -p "$HOME/File/Software/App/cava/kitty-audio-config" &


    KITTY_AUDIO_PID=$!

fi



# Start hyprlock
stdbuf -oL -eL hyprlock >> /tmp/lockscreenstyle.log 2>&1 &

HYPRLOCK_PID=$!



wait "$HYPRLOCK_PID"



# Cleanup
kill "$KITTY_AUDIO_PID" 2>/dev/null
kill "$KITTY_OVERLAY_PID" 2>/dev/null



if [ -f "$PID_FILE" ]; then

    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm "$PID_FILE"

fi



hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = "empty" }))'