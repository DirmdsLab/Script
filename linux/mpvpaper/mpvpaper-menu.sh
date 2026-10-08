#!/usr/bin/env bash

set -euo pipefail

readonly MPV_SOCKET="${MPV_SOCKET:-/tmp/mpv-socket}"
readonly SCALE_FILTER_LABEL="wofi-scale"
readonly FLIP_FILTER_LABEL="wofi-flip"

require_dependencies() {
    local dependency

    for dependency in jq socat wofi; do
        if ! command -v "$dependency" >/dev/null 2>&1; then
            printf 'Missing dependency: %s\n' "$dependency" >&2
            exit 1
        fi
    done

    if [[ ! -S "$MPV_SOCKET" ]]; then
        printf 'MPV IPC socket not found: %s\n' "$MPV_SOCKET" >&2
        exit 1
    fi
}

mpv_ipc() {
    local response

    if ! response=$(printf '%s\n' "$1" | socat -t 0.2 - "UNIX-CONNECT:$MPV_SOCKET"); then
        printf 'Failed to communicate with MPV.\n' >&2
        return 1
    fi

    printf '%s\n' "$response"
}

mpv_command() {
    local request response error

    request=$(jq -nc --args '$ARGS.positional | {command: .}' "$@")
    response=$(mpv_ipc "$request") || return 1
    error=$(jq -sr '[.[] | select(has("error")) | .error] | last // "No reply"' <<< "$response")

    if [[ "$error" != "success" ]]; then
        printf 'MPV command failed: %s\n' "$error" >&2
        return 1
    fi
}

mpv_properties() {
    local properties request response

    properties=$(jq -nc --args '$ARGS.positional' "$@")
    request=$(jq -nc --argjson properties "$properties" '
        $properties | to_entries[] |
        {command: ["get_property", .value], request_id: (.key + 1)}
    ')
    response=$(mpv_ipc "$request") || return 1

    jq -sc --argjson properties "$properties" '
        reduce .[] as $reply ({};
            if ($reply.request_id | type) == "number"
                and $reply.request_id >= 1
                and $reply.request_id <= ($properties | length)
            then
                .[$properties[$reply.request_id - 1]] =
                    (if $reply.error == "success" then $reply.data else null end)
            else
                .
            end
        )
        | if length == ($properties | length) then .
          else error("Incomplete MPV property response") end
    ' <<< "$response"
}

mpv_property() {
    mpv_properties "$1" | jq -cr --arg property "$1" '.[$property] // null'
}

menu_select() {
    local prompt="$1"
    shift

    printf '%s\n' "$@" | wofi --dmenu --insensitive --prompt "$prompt"
}

format_time() {
    local seconds="$1"

    if (( seconds >= 3600 )); then
        printf '%02d:%02d:%02d' "$((seconds / 3600))" "$(((seconds / 60) % 60))" "$((seconds % 60))"
    else
        printf '%02d:%02d' "$((seconds / 60))" "$((seconds % 60))"
    fi
}

get_status() {
    local properties current duration volume mute repeat shuffle position count
    local mute_text repeat_text shuffle_text

    properties=$(mpv_properties \
        time-pos duration volume mute loop-file shuffle playlist-pos playlist-count) || return 1

    IFS=$'\t' read -r current duration volume mute repeat shuffle position count <<< "$(
        jq -r '[
            (."time-pos" // 0 | floor),
            (.duration // 0 | floor),
            (.volume // 0 | round),
            (.mute // false),
            (."loop-file" // "no"),
            (.shuffle // false),
            (."playlist-pos" // -1),
            (."playlist-count" // 0)
        ] | @tsv' <<< "$properties"
    )"

    mute_text=$([[ "$mute" == "true" ]] && printf 'Muted' || printf 'Unmuted')
    repeat_text=$([[ "$repeat" == "inf" ]] && printf 'On' || printf 'Off')
    shuffle_text=$([[ "$shuffle" == "true" ]] && printf 'On' || printf 'Off')

    if (( position >= 0 )); then
        ((position += 1))
    else
        position=0
    fi

    printf '%s / %s | Vol: %s%% | %s | Repeat: %s | Shuffle: %s | %s/%s' \
        "$(format_time "$current")" "$(format_time "$duration")" \
        "$volume" "$mute_text" "$repeat_text" "$shuffle_text" "$position" "$count"
}

show_realtime_status() {
    local selection status

    while true; do
        status=$(get_status) || return 1
        selection=$(menu_select "$status" 'Refresh Status' 'Back') || return 0

        [[ "$selection" == 'Refresh Status' ]] || return 0
    done
}

set_volume() {
    local selection

    selection=$(menu_select 'Set Volume' \
        '25%' '30%' '40%' '50%' '60%' '75%' '100%') || return 0

    case "$selection" in
        '25%'|'30%'|'40%'|'50%'|'60%'|'75%'|'100%')
            mpv_command set_property volume "${selection%\%}"
            ;;
    esac
}

seek_video() {
    local selection seconds

    selection=$(menu_select 'Seek' \
        'Backward 10s' 'Backward 30s' 'Backward 60s' \
        'Forward 10s' 'Forward 30s' 'Forward 60s') || return 0

    case "$selection" in
        'Backward 10s') seconds=-10 ;;
        'Backward 30s') seconds=-30 ;;
        'Backward 60s') seconds=-60 ;;
        'Forward 10s')  seconds=10 ;;
        'Forward 30s')  seconds=30 ;;
        'Forward 60s')  seconds=60 ;;
        *) return 0 ;;
    esac

    mpv_command seek "$seconds" relative
}

select_playlist_item() {
    local playlist selection index
    local -a entries

    playlist=$(mpv_property playlist) || return 1
    mapfile -t entries < <(jq -r '
        . // [] | to_entries[] |
        "\(.key): \((.value.title // (.value.filename // "Unknown" | split("/") | last)) | gsub("[\\r\\n]"; " "))"
    ' <<< "$playlist")

    if (( ${#entries[@]} == 0 )); then
        printf 'The playlist is empty.\n' >&2
        return 0
    fi

    selection=$(menu_select 'Select Playlist Item' "${entries[@]}") || return 0

    if [[ "$selection" =~ ^([0-9]+): ]]; then
        index="${BASH_REMATCH[1]}"
        mpv_command playlist-play-index "$index"
    fi
}

add_video() {
    local path count

    path=$(menu_select 'Enter Video Path or URL' '') || return 0
    [[ -n "$path" ]] || return 0

    if [[ "$path" == '~/'* ]]; then
        path="$HOME/${path#\~/}"
    fi

    mpv_command loadfile "$path" append
    count=$(mpv_property playlist-count | jq -r '. // 0')

    if (( count > 0 )); then
        mpv_command playlist-play-index "$((count - 1))"
    fi
}

has_video_filter() {
    local filters

    filters=$(mpv_property vf) || return 1
    jq -e --arg label "$1" '
        any(.[]; .label == $label)
    ' <<< "$filters" >/dev/null
}

remove_video_filter() {
    local label="$1"

    if has_video_filter "$label"; then
        mpv_command vf remove "@$label"
    fi
}

set_video_scale() {
    local width="$1" height="$2"

    remove_video_filter "$SCALE_FILTER_LABEL"
    mpv_command vf add \
        "@$SCALE_FILTER_LABEL:lavfi=[scale=$width:$height:force_original_aspect_ratio=increase,crop=$width:$height]"
}

toggle_crop() {
    if has_video_filter "$SCALE_FILTER_LABEL"; then
        mpv_command vf remove "@$SCALE_FILTER_LABEL"
    else
        set_video_scale 1920 1080
    fi
}

flip_video() {
    if ! has_video_filter "$FLIP_FILTER_LABEL"; then
        mpv_command vf add "@$FLIP_FILTER_LABEL:hflip"
    fi
}

set_resolution() {
    local selection

    selection=$(menu_select 'Set Resolution' \
        '1080p' '720p' '480p' '360p' 'Original') || return 0

    case "$selection" in
        '1080p') set_video_scale 1920 1080 ;;
        '720p')  set_video_scale 1280 720 ;;
        '480p')  set_video_scale 854 480 ;;
        '360p')  set_video_scale 640 360 ;;
        'Original') remove_video_filter "$SCALE_FILTER_LABEL" ;;
    esac
}

toggle_shuffle() {
    local shuffle
    shuffle=$(mpv_property shuffle) || return 1

    if [[ "$shuffle" == 'true' ]]; then
        mpv_command set_property shuffle no
        mpv_command playlist-unshuffle
    else
        mpv_command set_property shuffle yes
        mpv_command playlist-shuffle
    fi
}

set_colors() {
    local request response

    request=$(jq -nc \
        --argjson contrast "$1" \
        --argjson brightness "$2" \
        --argjson gamma "$3" \
        --argjson saturation "$4" '
        [
            {command: ["set_property", "contrast", $contrast], request_id: 1},
            {command: ["set_property", "brightness", $brightness], request_id: 2},
            {command: ["set_property", "gamma", $gamma], request_id: 3},
            {command: ["set_property", "saturation", $saturation], request_id: 4}
        ] | .[]
    ')
    response=$(mpv_ipc "$request") || return 1

    if ! jq -se '
        [.[] | select(has("request_id"))] as $replies |
        ($replies | length) == 4 and all($replies[]; .error == "success")
    ' <<< "$response" >/dev/null; then
        printf 'Failed to apply color settings.\n' >&2
        return 1
    fi
}

read_color_value() {
    local name="$1" value

    value=$(menu_select "$name (-100 to 100)" '') || return 1

    if [[ ! "$value" =~ ^-?(100|[1-9]?[0-9])$ ]]; then
        printf 'Invalid %s value: expected an integer from -100 to 100.\n' "$name" >&2
        return 1
    fi

    printf '%s' "$value"
}

set_color_profile() {
    local properties status selection
    local contrast brightness gamma saturation

    properties=$(mpv_properties contrast brightness gamma saturation) || return 1
    status=$(jq -r '
        "C:\(.contrast // 0) B:\(.brightness // 0) G:\(.gamma // 0) S:\(.saturation // 0)"
    ' <<< "$properties")

    selection=$(menu_select "Color ($status)" \
        'Natural (Default)' 'Vivid Anime' 'Cinematic Dark' \
        'Bright & Punchy' 'Color Boost' 'Custom') || return 0

    case "$selection" in
        'Natural (Default)') set_colors 0 0 0 0 ;;
        'Vivid Anime')       set_colors 15 -5 8 25 ;;
        'Cinematic Dark')    set_colors 25 -15 12 5 ;;
        'Bright & Punchy')   set_colors 10 10 5 40 ;;
        'Color Boost')       set_colors 0 0 0 70 ;;
        'Custom')
            contrast=$(read_color_value 'Contrast') || return 0
            brightness=$(read_color_value 'Brightness') || return 0
            gamma=$(read_color_value 'Gamma') || return 0
            saturation=$(read_color_value 'Saturation') || return 0
            set_colors "$contrast" "$brightness" "$gamma" "$saturation"
            ;;
    esac
}

show_video_info() {
    local properties
    local -a info

    properties=$(mpv_properties \
        path video-params/w video-params/h dwidth dheight \
        container-fps estimated-vf-fps) || return 1

    mapfile -t info < <(jq -r '
        [
            "File: \(.path // "N/A")",
            "FPS (File): \(."container-fps" // "N/A")",
            "FPS (Playback): \(."estimated-vf-fps" // "N/A")",
            "Original: \(."video-params/w" // "N/A")x\(."video-params/h" // "N/A")",
            "Output: \(.dwidth // "N/A")x\(.dheight // "N/A")"
        ] | .[]
    ' <<< "$properties")

    menu_select 'Video Info' "${info[@]}" >/dev/null || true
}

main() {
    local selection status

    require_dependencies
    status=$(get_status)

    selection=$(menu_select "$status" \
        'Play/Pause' 'Next' 'Previous' 'Volume Control' 'Seek Control' \
        'Select Playlist Item' 'Add Video to Playlist' \
        'Set Aspect Ratio 16:9' 'Reset Aspect Ratio' \
        'Toggle Scale Crop' 'Reset Scale Crop' 'Toggle Shuffle' \
        'Flip Horizontally' 'Reset Flip' 'Toggle Repeat' 'Toggle Mute' \
        'Set Color' 'Set Resolution' 'Video Info' 'Real-Time Status') || return 0

    case "$selection" in
        'Play/Pause')            mpv_command cycle pause ;;
        'Next')                  mpv_command playlist-next ;;
        'Previous')              mpv_command playlist-prev ;;
        'Volume Control')        set_volume ;;
        'Seek Control')          seek_video ;;
        'Select Playlist Item')  select_playlist_item ;;
        'Add Video to Playlist') add_video ;;
        'Set Aspect Ratio 16:9') mpv_command set_property video-aspect-override '16:9' ;;
        'Reset Aspect Ratio')    mpv_command set_property video-aspect-override no ;;
        'Toggle Scale Crop')     toggle_crop ;;
        'Reset Scale Crop')      remove_video_filter "$SCALE_FILTER_LABEL" ;;
        'Toggle Shuffle')       toggle_shuffle ;;
        'Flip Horizontally')     flip_video ;;
        'Reset Flip')            remove_video_filter "$FLIP_FILTER_LABEL" ;;
        'Toggle Repeat')        mpv_command cycle-values loop-file inf no ;;
        'Toggle Mute')          mpv_command cycle mute ;;
        'Set Color')            set_color_profile ;;
        'Set Resolution')       set_resolution ;;
        'Video Info')           show_video_info ;;
        'Real-Time Status')     show_realtime_status ;;
    esac
}

main "$@"
