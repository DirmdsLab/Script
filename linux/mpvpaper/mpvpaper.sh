
#!/usr/bin/env bash

set -euo pipefail

# Configuration
PLAYLIST_DIR="$HOME/Playlists"
VIDEO_DIR="$HOME/Videos/Wallpapers"
CACHE_DIR="/tmp/hypr-mpv_tmp"
SOCKET_PATH="/tmp/mpv-socket"
OUTPUT_NAME="DP-1"

BASE_OPTS="--no-config --vf=scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,fps=60 volume=40 input-ipc-server=$SOCKET_PATH"

# Determine the playback type from a file extension.
get_media_type() {
    local path="${1,,}"

    case "$path" in
        *.m3u) printf 'playlist\n' ;;
        *.mp4|*.mkv|*.webm|*.avi|*.mov) printf 'video\n' ;;
        *) return 1 ;;
    esac
}

# Browse folders and select a file using wofi.
# Modes: playlist, video, media, any.
browse_files() {
    local root_dir="$1"
    local mode="$2"
    local current_dir="$root_dir"
    local selected file directory
    local -a files folders entries

    if [[ ! -d "$root_dir" ]]; then
        printf 'Directory not found: %s\n' "$root_dir" >&2
        return 1
    fi

    while true; do
        mapfile -d '' -t folders < <(
            find -L "$current_dir" -mindepth 1 -maxdepth 1 \
                -type d ! -name '.*' -printf '%T@ %f\0' |
                sort -zrn | cut -z -d ' ' -f2-
        )

        case "$mode" in
            playlist)
                mapfile -d '' -t files < <(
                    find -L "$current_dir" -mindepth 1 -maxdepth 1 \
                        -type f -iname '*.m3u' -printf '%T@ %f\0' |
                        sort -zrn | cut -z -d ' ' -f2-
                )
                ;;
            video)
                mapfile -d '' -t files < <(
                    find -L "$current_dir" -mindepth 1 -maxdepth 1 \
                        -type f \( -iname '*.mp4' -o -iname '*.mkv' \
                        -o -iname '*.webm' -o -iname '*.avi' \
                        -o -iname '*.mov' \) -printf '%T@ %f\0' |
                        sort -zrn | cut -z -d ' ' -f2-
                )
                ;;
            media)
                mapfile -d '' -t files < <(
                    find -L "$current_dir" -mindepth 1 -maxdepth 1 \
                        -type f ! -name '.*' \
                        \( -iname '*.m3u' -o -iname '*.mp4' \
                        -o -iname '*.mkv' -o -iname '*.webm' \
                        -o -iname '*.avi' -o -iname '*.mov' \) \
                        -printf '%T@ %f\0' |
                        sort -zrn | cut -z -d ' ' -f2-
                )
                ;;
            any)
                mapfile -d '' -t files < <(
                    find -L "$current_dir" -mindepth 1 -maxdepth 1 \
                        -type f ! -name '.*' -printf '%T@ %f\0' |
                        sort -zrn | cut -z -d ' ' -f2-
                )
                ;;
        esac

        entries=("Back to Main Menu")

        if [[ "$mode" == "media" && "$current_dir" != "$HOME" ]] || \
            { [[ "$mode" != "media" ]] && [[ "$current_dir" != "$root_dir" ]]; }; then
            entries=("Go Up" "${entries[@]}")
        fi

        if [[ "$mode" == "any" ]]; then
            entries=("Enter Path Manually" "${entries[@]}")
        fi

        for file in "${files[@]}"; do
            entries+=("[File] $file")
        done

        for directory in "${folders[@]}"; do
            entries+=("[Directory] $directory")
        done

        if ! selected=$(printf '%s\n' "${entries[@]}" |
            wofi --dmenu --insensitive --prompt "Browse: $current_dir"); then
            return 1
        fi

        [[ -n "$selected" ]] || return 1

        case "$selected" in
            "Back to Main Menu")
                return 2
                ;;
            "Go Up")
                current_dir=$(dirname -- "$current_dir")
                ;;
            "Enter Path Manually")
                if ! selected=$(wofi --dmenu --insensitive --prompt "Enter full file path"); then
                    return 1
                fi
                [[ -n "$selected" ]] || return 1
                printf '%s\n' "$selected"
                return 0
                ;;
            "[Directory] "*)
                current_dir="$current_dir/${selected#\[Directory\] }"
                ;;
            "[File] "*)
                printf '%s\n' "$current_dir/${selected#\[File\] }"
                return 0
                ;;
        esac
    done
}

# Stop existing mpvpaper processes and their child processes.
stop_mpvpaper() {
    local pid
    local -a pids

    mapfile -t pids < <(pgrep -f 'mpvpaper -o' || true)

    if (( ${#pids[@]} == 0 )); then
        printf 'No running mpvpaper process found.\n'
        return 0
    fi

    for pid in "${pids[@]}"; do
        pkill -TERM -P "$pid" 2>/dev/null || true
        kill -TERM "$pid" 2>/dev/null || true
    done

    printf 'Stopped mpvpaper processes.\n'
}

# Remove cached video files older than three days.
cleanup_video_cache() {
    [[ -d "$CACHE_DIR" ]] || return 0

    find "$CACHE_DIR" -maxdepth 1 -type f -mmin +4320 -delete
}

# Copy symlinked videos into the cache before playback.
cache_symlink_video() {
    local cached_video temporary_copy

    [[ -L "$SELECTED" ]] || return 0

    mkdir -p -- "$CACHE_DIR"
    cached_video="$CACHE_DIR/$(basename -- "$SELECTED")"

    if [[ -f "$cached_video" ]]; then
        printf 'Using cached video: %s\n' "$cached_video"
        SELECTED="$cached_video"
        return 0
    fi

    printf 'Caching symlink video: %s\n' "$SELECTED"
    notify-send 'mpvpaper' 'Copying video to cache' 2>/dev/null || true

    temporary_copy=$(mktemp "$CACHE_DIR/.copy.XXXXXXXX") || return 1

    if ! cp -- "$SELECTED" "$temporary_copy"; then
        rm -f -- "$temporary_copy"
        printf 'Failed to copy video to cache: %s\n' "$SELECTED" >&2
        return 1
    fi

    if ! mv -- "$temporary_copy" "$cached_video"; then
        rm -f -- "$temporary_copy"
        printf 'Failed to finalize cached video: %s\n' "$cached_video" >&2
        return 1
    fi

    SELECTED="$cached_video"
}

# Select media from the main menu.
choose_from_menu() {
    local choice selected_file status

    while true; do
        if ! choice=$(printf '%s\n' \
            'Playlist' 'Video' 'Explorer Path' 'Input Path Manual' |
            wofi --dmenu --insensitive --prompt 'Select source'); then
            return 1
        fi

        [[ -n "$choice" ]] || return 1

        case "$choice" in
            Playlist)
                if selected_file=$(browse_files "$PLAYLIST_DIR" playlist); then
                    SELECTED="$selected_file"
                    MEDIA_TYPE=playlist
                    return 0
                else
                    status=$?
                fi
                ;;
            Video)
                if selected_file=$(browse_files "$VIDEO_DIR" video); then
                    SELECTED="$selected_file"
                    MEDIA_TYPE=video
                    return 0
                else
                    status=$?
                fi
                ;;
            'Explorer Path')
                if selected_file=$(browse_files "$VIDEO_DIR" media); then
                    SELECTED="$selected_file"
                    MEDIA_TYPE=$(get_media_type "$SELECTED")
                    return 0
                else
                    status=$?
                fi
                ;;
            'Input Path Manual')
                if ! selected_file=$(wofi --dmenu --insensitive --prompt 'Enter full file path'); then
                    return 1
                fi
                [[ -n "$selected_file" ]] || return 1
                SELECTED="$selected_file"
                MEDIA_TYPE=$(get_media_type "$SELECTED") || {
                    printf 'Unsupported file format: %s\n' "$SELECTED" >&2
                    return 1
                }
                return 0
                ;;
            *)
                printf 'Invalid menu selection: %s\n' "$choice" >&2
                return 1
                ;;
        esac

        if (( status != 2 )); then
            return "$status"
        fi
    done
}

main() {
    local command="${1:-}"
    local selected_file

    SELECTED=''
    MEDIA_TYPE=''

    case "$command" in
        kill)
            stop_mpvpaper
            return 0
            ;;
        videoplay|playlistplay)
            if (( $# < 2 )); then
                printf 'Usage: %s %s <file-path>\n' "$0" "$command" >&2
                return 1
            fi
            SELECTED="$2"
            if [[ "$command" == videoplay ]]; then
                MEDIA_TYPE=video
            else
                MEDIA_TYPE=playlist
            fi
            ;;
        wofiinput)
            if selected_file=$(browse_files "$HOME" any); then
                SELECTED="$selected_file"
                MEDIA_TYPE=$(get_media_type "$SELECTED") || {
                    printf 'Unsupported file format: %s\n' "$SELECTED" >&2
                    return 1
                }
            else
                return 0
            fi
            ;;
        *)
            if ! choose_from_menu; then
                return 0
            fi
            ;;
    esac

    if [[ ! -f "$SELECTED" ]]; then
        printf 'File not found: %s\n' "$SELECTED" >&2
        return 1
    fi

    cleanup_video_cache

    local mpv_options="$BASE_OPTS --loop"

    if [[ "$MEDIA_TYPE" == playlist ]]; then
        mpv_options+=' --loop-playlist'
    else
        cache_symlink_video || return 1
    fi

    stop_mpvpaper
    printf 'Starting mpvpaper with: %s\n' "$SELECTED"
    mpvpaper -o "$mpv_options" "$OUTPUT_NAME" "$SELECTED"
}

main "$@"
