#!/usr/bin/env bash

PID_FILE="/tmp/wallpaper.pid"
MONITOR="DP-1"
VIDEO_DIR="$HOME/Videos/Wallpapers"
TMP_DIR="/tmp/hypr-mpv_tmp"
LOG="/tmp/lockscreenstyle.log"

VIDEO=""
SKIP_EFFECTS=false
NO_AUDIO_VISUAL=false
USE_IPC=false
USE_MIRROR=false
KITTY_AUDIO_PID=""
KITTY_OVERLAY_PID=""

# Create the cache directory before building the video list.
mkdir -p -- "$TMP_DIR" || exit 1

# Check direct video path argument.
if [[ "${1:-}" == "videopath" && -n "${2:-}" ]]; then
    VIDEO="$2"
    SKIP_EFFECTS=true
else
    # Collect accessible source videos.
    # Broken symlinks are excluded because find follows their targets.
    declare -A AVAILABLE_SOURCE_NAMES=()
    declare -a FILES=()
    declare -a LABELS=()

    if [[ -d "$VIDEO_DIR" ]]; then
        while IFS= read -r -d '' SOURCE_PATH; do
            [[ -f "$SOURCE_PATH" && -r "$SOURCE_PATH" ]] || continue

            BASE_NAME=$(basename -- "$SOURCE_PATH")
            SOURCE_KEY="${BASE_NAME,,}"

            AVAILABLE_SOURCE_NAMES["$SOURCE_KEY"]=1
            FILES+=("$SOURCE_PATH")
            LABELS+=("$BASE_NAME")
        done < <(
            find -L "$VIDEO_DIR" \
                -type f \
                \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.m3u' \) \
                -printf '%T@ %p\0' 2>/dev/null |
                sort -z -t ' ' -k1,1nr |
                cut -z -d ' ' -f2-
        )
    fi

    # Add cached videos unless an accessible source has the same filename.
    while IFS= read -r -d '' CACHE_PATH; do
        [[ -f "$CACHE_PATH" && -r "$CACHE_PATH" ]] || continue

        BASE_NAME=$(basename -- "$CACHE_PATH")
        CACHE_KEY="${BASE_NAME,,}"

        if [[ -n "${AVAILABLE_SOURCE_NAMES[$CACHE_KEY]+x}" ]]; then
            continue
        fi

        FILES+=("$CACHE_PATH")
        LABELS+=("[TMP] $BASE_NAME")
    done < <(
        find "$TMP_DIR" \
            -maxdepth 1 \
            -type f \
            \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.m3u' \) \
            -printf '%T@ %p\0' 2>/dev/null |
            sort -z -t ' ' -k1,1nr |
            cut -z -d ' ' -f2-
    )

    # Exit if no videos are available.
    if ((${#FILES[@]} == 0)); then
        notify-send "No video wallpapers found" 2>/dev/null || true
        exit 0
    fi

    # Disambiguate duplicate display labels.
    declare -a DISPLAY_LABELS=()

    for i in "${!FILES[@]}"; do
        LABEL="${LABELS[$i]}"
        MATCH_COUNT=0

        for OTHER_LABEL in "${LABELS[@]}"; do
            if [[ "$OTHER_LABEL" == "$LABEL" ]]; then
                ((MATCH_COUNT += 1))
            fi
        done

        if ((MATCH_COUNT > 1)); then
            LABEL="$LABEL - $(dirname -- "${FILES[$i]}")"
        fi

        DISPLAY_LABELS+=("$LABEL")
    done

    # Display video selector.
    if ! MENU=$(
        printf '%s\n' "${DISPLAY_LABELS[@]}" |
            wofi \
                --dmenu \
                --insensitive \
                --prompt "Select Video Wallpaper"
    ); then
        exit 0
    fi

    [[ -n "$MENU" ]] || exit 0

    # Resolve the selected video path.
    for i in "${!DISPLAY_LABELS[@]}"; do
        if [[ "${DISPLAY_LABELS[$i]}" == "$MENU" ]]; then
            VIDEO="${FILES[$i]}"
            break
        fi
    done
fi

[[ -n "$VIDEO" ]] || exit 0

# Use the cached copy if a directly supplied symlink is broken.
if [[ -L "$VIDEO" && ! -e "$VIDEO" ]]; then
    CACHE_VIDEO="$TMP_DIR/$(basename -- "$VIDEO")"

    if [[ -f "$CACHE_VIDEO" ]]; then
        VIDEO="$CACHE_VIDEO"
    else
        notify-send "Source video unavailable and cache not found" 2>/dev/null || true
        exit 1
    fi
fi

# Refresh the selected cache before cleanup.
# This prevents an expired selected cache from being deleted before playback.
if [[ "$VIDEO" == "$TMP_DIR/"* ]]; then
    touch -- "$VIDEO" || exit 1
elif [[ -L "$VIDEO" ]]; then
    SELECTED_CACHE="$TMP_DIR/$(basename -- "$VIDEO")"

    if [[ -f "$SELECTED_CACHE" ]]; then
        touch -- "$SELECTED_CACHE" || exit 1
    fi
fi

# Delete cached files older than three days.
find "$TMP_DIR" \
    -maxdepth 1 \
    -type f \
    -mmin +4320 \
    -delete

# Cache symlink videos using the existing atomic copy mechanism.
if [[ -L "$VIDEO" ]]; then
    CACHE_VIDEO="$TMP_DIR/$(basename -- "$VIDEO")"

    if [[ ! -f "$CACHE_VIDEO" ]]; then
        notify-send "Copying to tmp" 2>/dev/null || true
        echo "Caching symlink video: $VIDEO"

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

    # Reset cache expiration whenever the selected symlink cache is used.
    touch -- "$CACHE_VIDEO" || exit 1
    VIDEO="$CACHE_VIDEO"

elif [[ "$VIDEO" == "$TMP_DIR/"* ]]; then
    # Reset cache expiration when a cached video is selected directly.
    touch -- "$VIDEO" || exit 1
fi

# Base mpv options.
MPV_OPTS='--title=mpvpaperhyprlock --no-config volume=100 --loop --loop-playlist shuffle'

# Video filter.
VIDEO_FILTER="scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,fps=60"

# Effect selector.
if [[ "$SKIP_EFFECTS" == false ]]; then
    EFFECT_LIST=(
        "Color Up"
        "Mirror Horizontal"
        "Mute"
        "Disable Audio Visual"
    )

    SELECTED_EFFECTS=()

    while true; do
        MENU="None\n"

        for EFFECT_ITEM in "${EFFECT_LIST[@]}"; do
            CHECK="[ ]"

            for SELECTED in "${SELECTED_EFFECTS[@]}"; do
                if [[ "$SELECTED" == "$EFFECT_ITEM" ]]; then
                    CHECK="[x]"
                    break
                fi
            done

            MENU+="$CHECK $EFFECT_ITEM\n"
        done

        MENU+="Apply"

        if ! CHOICE=$(
            printf "%b" "$MENU" |
                wofi \
                    --dmenu \
                    --prompt "Select Effects"
        ); then
            break
        fi

        [[ -n "$CHOICE" ]] || break

        EFFECT=$(printf '%s\n' "$CHOICE" | sed 's/^\[[ x]\] //')

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

                for SELECTED in "${SELECTED_EFFECTS[@]}"; do
                    if [[ "$SELECTED" == "$EFFECT" ]]; then
                        FOUND=true
                    else
                        NEW_SELECTION+=("$SELECTED")
                    fi
                done

                if [[ "$FOUND" == false ]]; then
                    NEW_SELECTION+=("$EFFECT")
                fi

                SELECTED_EFFECTS=("${NEW_SELECTION[@]}")
                ;;
        esac
    done

    # Apply selected effects.
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

# Add mirror filter.
if [[ "$USE_MIRROR" == true ]]; then
    VIDEO_FILTER="$VIDEO_FILTER,hflip"
fi

# Add final video filter.
MPV_OPTS="$MPV_OPTS --vf=$VIDEO_FILTER"

# Stop previous wallpaper.
if [[ -f "$PID_FILE" ]]; then
    OLD_PID=$(cat "$PID_FILE")
    kill "$OLD_PID" 2>/dev/null || true
    rm -f -- "$PID_FILE"
fi

# Close special workspaces.
for WORKSPACE in Hmm Hmph UwU magic UxU sysmon; do
    hyprctl monitors -j |
        jq -e ".[] | select(.specialWorkspace.name==\"special:$WORKSPACE\" and .specialWorkspace.id!=-1)" \
            >/dev/null &&
        hyprctl eval "hl.dispatch(hl.dsp.workspace.toggle_special(\"$WORKSPACE\"))"
done

sleep 0.5

hyprctl dispatch "hl.dsp.focus({ workspace = 21 })"

# Remove old IPC socket.
rm -f /tmp/mpvlock-socket

# Start wallpaper.
mpvpaper -o "$MPV_OPTS" "$MONITOR" "$VIDEO" -f &

sleep 0.5

PID=$(pgrep -f 'mpv.*mpvpaperhyprlock' | head -n 1)
echo "$PID" > "$PID_FILE"

: > /tmp/lockscreenstyle.log

# Apply saturation if IPC is enabled.
if [[ "$USE_IPC" == true ]]; then
    sleep 0.5

    if [[ -S /tmp/mpvlock-socket ]]; then
        echo '{ "command": ["set_property", "saturation", 70] }' |
            socat - /tmp/mpvlock-socket
    fi
fi

# Start Kitty overlay.
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

# Start CAVA.
if [[ "$NO_AUDIO_VISUAL" != true ]]; then
    kitty \
        --class kitty-audio \
        --config "$HOME/File/Software/App/kitty/kitty-transparant.conf" \
        -e cava \
        -p "$HOME/File/Software/App/cava/kitty-audio-config" &

    KITTY_AUDIO_PID=$!
fi

# Pause wallpaper after 10 seconds.
(
    sleep 10
    notify-send "pause"

    printf '{"command":["set_property","pause",true]}\n' |
        socat - UNIX-CONNECT:/tmp/mpv-socket >/dev/null 2>&1
) &

# Start hyprlock.
stdbuf -oL -eL hyprlock >> /tmp/lockscreenstyle.log 2>&1 &

HYPRLOCK_PID=$!

echo "[INFO] $(date '+%F %T') Starting hyprlock..." >> "$LOG"

LOCK_START=$(date +%s)

wait "$HYPRLOCK_PID"
STATUS=$?

# Cleanup.
if [[ -n "$KITTY_AUDIO_PID" ]]; then
    kill "$KITTY_AUDIO_PID" 2>/dev/null || true
fi

if [[ -n "$KITTY_OVERLAY_PID" ]]; then
    kill "$KITTY_OVERLAY_PID" 2>/dev/null || true
fi

if [[ -f "$PID_FILE" ]]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f -- "$PID_FILE"
fi

# Calculate lock duration.
LOCK_END=$(date +%s)
LOCK_DURATION=$((LOCK_END - LOCK_START))

# Format duration as HH:MM:SS.
HOURS=$((LOCK_DURATION / 3600))
MINUTES=$(((LOCK_DURATION % 3600) / 60))
SECONDS=$((LOCK_DURATION % 60))

LOCK_DURATION_FMT=$(printf '%02d:%02d:%02d' "$HOURS" "$MINUTES" "$SECONDS")

echo "[INFO] $(date '+%F %T') hyprlock exited with status $STATUS" >> "$LOG"
echo "[INFO] $(date '+%F %T') Lock duration: ${LOCK_DURATION_FMT} (${LOCK_DURATION}s)" >> "$LOG"

notify-send "unlock" "Lock duration: ${LOCK_DURATION_FMT}"

hyprctl eval 'hl.dispatch(hl.dsp.focus({ workspace = "empty" }))'
