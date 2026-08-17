#!/usr/bin/env bash

SOCKET="/tmp/mpv-socket"

get_shuffle_status() {
    shuffle=$(echo '{ "command": ["get_property", "shuffle"] }' | socat - "$SOCKET" 2>/dev/null | jq -r '.data // "false"')
    if [ "$shuffle" = "true" ]; then
        echo "Shuffle"
    else
        echo "Sort"
    fi
}


get_status() {
    cur_time=$(echo '{ "command": ["get_property", "time-pos"] }' | socat - "$SOCKET" 2>/dev/null | jq '.data // 0' )
    cur_time=${cur_time%.*}
    duration=$(echo '{ "command": ["get_property", "duration"] }' | socat - "$SOCKET" 2>/dev/null | jq '.data // 0' )
    duration=${duration%.*}
    format_time() {
        local T=$1
        printf "%02d:%02d" $((T/60)) $((T%60))
    }
    cur_time_fmt=$(format_time $cur_time)
    duration_fmt=$(format_time $duration)
    volume=$(echo '{ "command": ["get_property", "volume"] }' | socat - "$SOCKET" 2>/dev/null | jq '.data // 0' | awk '{printf "%.0f", $0}')
    mute=$(echo '{ "command": ["get_property", "mute"] }' | socat - "$SOCKET" 2>/dev/null | jq -r '.data // "false"')
    playlist_pos=$(echo '{ "command": ["get_property", "playlist-pos"] }' | socat - "$SOCKET" 2>/dev/null | jq '.data // 0')
    playlist_count=$(echo '{ "command": ["get_property", "playlist-count"] }' | socat - "$SOCKET" 2>/dev/null | jq '.data // 0')
    if [ "$mute" = "true" ]; then
        mute_status="Muted"
    else
        mute_status="Unmuted"
    fi
    shuffle_status=$(get_shuffle_status)


    loop_file=$(echo '{ "command": ["get_property", "loop-file"] }' | socat - "$SOCKET" 2>/dev/null | jq -r '.data')
    if [ "$loop_file" = "inf" ]; then
        loop_status="Repeat: On"
    else
        loop_status="Repeat: Off"
    fi



    #echo "▶ $cur_time_fmt / $duration_fmt | Vol: $volume% | $mute_status | Playlist: $((playlist_pos+1))/$playlist_count"
    echo "▶ $cur_time_fmt / $duration_fmt | Vol: $volume% | $mute_status | $loop_status | Mode: $shuffle_status | $((playlist_pos+1))/$playlist_count"

}

set_aspect_16_9() {
    echo '{ "command": ["set_property", "video-aspect-override", "16:9"] }' | socat - "$SOCKET"
}

reset_aspect() {
    echo '{ "command": ["set_property", "video-aspect-override", 0] }' | socat - "$SOCKET"
}

set_crop_scale() {
    echo '{ "command": ["set_property", "vf", "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080"] }' | socat - /tmp/mpv-socket
}

reset_scale() {
    echo '{ "command": ["set_property", "vf", "scale=1920:1080"] }' | socat - /tmp/mpv-socket
}


status_realtime_menu() {
    while true; do
        header=$(get_status)
        echo "get" | wofi --dmenu --prompt "$header" > /dev/null
        [ $? -ne 0 ] && break  
    done
}


shuffle_playlist_safely() {
    local playlist_json=$(echo '{ "command": ["get_property", "playlist"] }' | socat - "$SOCKET")
    local total=$(echo "$playlist_json" | jq '.data | length')
    local current=$(echo '{ "command": ["get_property", "playlist-pos"] }' | socat - "$SOCKET" | jq '.data // 0')

    mapfile -t indexes < <(seq 0 $((total - 1)))
    shuffled=($(printf "%s\n" "${indexes[@]}" | shuf))

    declare -A new_positions
    for i in "${!shuffled[@]}"; do
        new_positions[${shuffled[$i]}]=$i
    done

    for ((i=0; i<total; i++)); do
        from=${shuffled[$i]}
        to=$i

        if [ "$from" -ne "$to" ]; then
            echo '{ "command": ["playlist-move", '"$from"', '"$to"'] }' | socat - "$SOCKET"

            
            for ((j=0; j<${#shuffled[@]}; j++)); do
                if [ "${shuffled[$j]}" -eq "$from" ]; then
                    shuffled[$j]=$to
                elif [ "${shuffled[$j]}" -eq "$to" ]; then
                    shuffled[$j]=$from
                fi
            done
        fi
    done
}


header=$(get_status)

main_menu=$(printf "Play/Pause\nNext\nPrevious\nVolume Control\nSeek Control\nPilih Playlist\nTambah Video ke Playlist\nSet Aspect Ratio 16:9\nReset Aspect Ratio\nToggle Scale Crop\nReset Scale Crop\nToggle Shuffle\nFlip\nNormal\nToggle Repeat\nToggle Mute\nSet Color\nSet Resolution\nVideo Info\nStatus Real-Time" | wofi --dmenu --insensitive --prompt "$header"
)


case "$main_menu" in

    "Play/Pause")
        echo '{ "command": ["cycle", "pause"] }' | socat - "$SOCKET"
        ;;

    "Next")
        echo '{ "command": ["playlist-next"] }' | socat - "$SOCKET"
        ;;

    "Previous")
        echo '{ "command": ["playlist-prev"] }' | socat - "$SOCKET"
        ;;

    "Volume Control")
        vol_option=$(printf "Set Volume 25%%\nSet Volume 30%%\nSet Volume 40%%\nSet Volume 50%%\nSet Volume 60%%\nSet Volume 75%%\nSet Volume 100%%" | wofi --dmenu --prompt "Set Volume")
        case "$vol_option" in
            "Set Volume 25%")
                echo '{ "command": ["set_property", "volume", 25] }' | socat - "$SOCKET"
                ;;
            "Set Volume 30%")
                echo '{ "command": ["set_property", "volume", 30] }' | socat - "$SOCKET"
                ;;
            "Set Volume 40%")
                echo '{ "command": ["set_property", "volume", 40] }' | socat - "$SOCKET"
                ;;
            "Set Volume 50%")
                echo '{ "command": ["set_property", "volume", 50] }' | socat - "$SOCKET"
                ;;
            "Set Volume 60%")
                echo '{ "command": ["set_property", "volume", 60] }' | socat - "$SOCKET"
                ;;
            "Set Volume 75%")
                echo '{ "command": ["set_property", "volume", 75] }' | socat - "$SOCKET"
                ;;
            "Set Volume 100%")
                echo '{ "command": ["set_property", "volume", 100] }' | socat - "$SOCKET"
                ;;
        esac
        ;;


    "Seek Control")
        seek_option=$(printf "Seek Backward 10s\nSeek Backward 30s\nSeek Backward 60s\nSeek Forward 10s\nSeek Forward 30s\nSeek Forward 60s" | wofi --dmenu --prompt "Seek")
        case "$seek_option" in
            "Seek Backward 10s")
                echo '{ "command": ["seek", -10, "relative"] }' | socat - "$SOCKET"
                ;;
            "Seek Backward 30s")
                echo '{ "command": ["seek", -30, "relative"] }' | socat - "$SOCKET"
                ;;
            "Seek Backward 60s")
                echo '{ "command": ["seek", -60, "relative"] }' | socat - "$SOCKET"
                ;;
            "Seek Forward 10s")
                echo '{ "command": ["seek", 10, "relative"] }' | socat - "$SOCKET"
                ;;
            "Seek Forward 30s")
                echo '{ "command": ["seek", 30, "relative"] }' | socat - "$SOCKET"
                ;;
            "Seek Forward 60s")
                echo '{ "command": ["seek", 60, "relative"] }' | socat - "$SOCKET"
                ;;
        esac
        ;;

    "Pilih Playlist")
        PLAYLIST=$(echo '{ "command": ["get_property", "playlist"] }' | socat - "$SOCKET")
        OPTIONS=$(echo "$PLAYLIST" | jq -r '.data[] | .filename' | nl -v 0 | awk -F'\t' '{print $1 ":" $2}' | awk -F'/' '{split($0,a,":"); print a[1] ":" $NF}')
        SELECTED=$(echo "$OPTIONS" | wofi --dmenu --prompt "Pilih Item Playlist")
        INDEX=$(echo "$SELECTED" | cut -d':' -f1)
        echo '{ "command": ["playlist-play-index", '"$INDEX"'] }' | socat - "$SOCKET"
        ;;

    "Tambah Video ke Playlist")
        video_path=$(wofi --dmenu --prompt "Masukkan path video")
        if [ -n "$video_path" ]; then
            echo '{ "command": ["loadfile", "'"$video_path"'", "append-play"] }' | socat - "$SOCKET"

            sleep 0.2 
            playlist_count=$(echo '{ "command": ["get_property", "playlist-count"] }' | socat - "$SOCKET" | jq '.data // 0')
            last_index=$((playlist_count - 1))
            echo '{ "command": ["playlist-play-index", '"$last_index"'] }' | socat - "$SOCKET"
        fi
        ;;
    "Set Aspect Ratio 16:9")
        set_aspect_16_9
        ;;

    "Reset Aspect Ratio")
        reset_aspect
        ;;
    "Toggle Scale Crop")
        set_crop_scale
        ;;

    "Reset Scale Crop")
        reset_scale
        ;;
    "Toggle Shuffle")
    shuffle_playlist_safely
    ;;
    "Flip")
        echo '{ "command": ["vf", "add", "hflip"] }' | socat - "$SOCKET"
        ;;

    "Normal")
        echo '{ "command": ["vf", "remove", "hflip"] }' | socat - "$SOCKET"
        ;;
    
    "Toggle Repeat")
    loop_status=$(echo '{ "command": ["get_property", "loop-file"] }' | socat - "$SOCKET" 2>/dev/null | jq -r '.data')
    
    
    
    if [ "$loop_status" = "inf" ]; then
        echo '{ "command": ["set_property", "loop-file", "no"] }' | socat - "$SOCKET"
    else
        
        echo '{ "command": ["set_property", "loop-file", "inf"] }' | socat - "$SOCKET"
    fi
    ;;
    
    "Toggle Mute")
        MUTE_STATUS=$(echo '{ "command": ["get_property", "mute"] }' | socat - "$SOCKET" 2>/dev/null | jq -r '.data')
        if [ "$MUTE_STATUS" = "true" ]; then
            echo '{ "command": ["set_property", "mute", false] }' | socat - "$SOCKET"
        else
            echo '{ "command": ["set_property", "mute", true] }' | socat - "$SOCKET"
        fi
        ;;


"Set Color")
    
    CURRENT_CONTRAST=$(echo '{ "command": ["get_property", "contrast"] }' | socat - "$SOCKET" 2>/dev/null | jq -r '.data')
    CURRENT_BRIGHTNESS=$(echo '{ "command": ["get_property", "brightness"] }' | socat - "$SOCKET" 2>/dev/null | jq -r '.data')
    CURRENT_GAMMA=$(echo '{ "command": ["get_property", "gamma"] }' | socat - "$SOCKET" 2>/dev/null | jq -r '.data')
    CURRENT_SATURATION=$(echo '{ "command": ["get_property", "saturation"] }' | socat - "$SOCKET" 2>/dev/null | jq -r '.data')

    STATUS="Current: C=$CURRENT_CONTRAST B=$CURRENT_BRIGHTNESS G=$CURRENT_GAMMA S=$CURRENT_SATURATION"

    
    CHOICE=$(printf "Natural (Default)\nVivid Anime\nCinematic Dark\nBright & Punchy\nColor Boost\nCustom" | \
             wofi --dmenu --prompt "Set Color ($STATUS)")

    case "$CHOICE" in
        "Natural (Default)")
            echo '{ "command": ["set_property", "contrast", 0] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "brightness", 0] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "gamma", 0] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "saturation", 0] }' | socat - "$SOCKET"
            ;;
        "Vivid Anime")
            echo '{ "command": ["set_property", "contrast", 15] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "brightness", -5] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "gamma", 8] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "saturation", 25] }' | socat - "$SOCKET"
            ;;
        "Cinematic Dark")
            echo '{ "command": ["set_property", "contrast", 25] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "brightness", -15] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "gamma", 12] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "saturation", 5] }' | socat - "$SOCKET"
            ;;
        "Bright & Punchy")
            echo '{ "command": ["set_property", "contrast", 10] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "brightness", 10] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "gamma", 5] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "saturation", 40] }' | socat - "$SOCKET"
            ;;
        "Color Boost")
            echo '{ "command": ["set_property", "contrast", 0] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "brightness", 0] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "gamma", 0] }' | socat - "$SOCKET"
            echo '{ "command": ["set_property", "saturation", 70] }' | socat - "$SOCKET"
            ;;
        "Custom")
            CONTRAST=$(wofi --dmenu --prompt "Contrast (-100..100):")
            BRIGHTNESS=$(wofi --dmenu --prompt "Brightness (-100..100):")
            GAMMA=$(wofi --dmenu --prompt "Gamma (-100..100):")
            SATURATION=$(wofi --dmenu --prompt "Saturation (-100..100):")

            [ -n "$CONTRAST" ] && echo "{ \"command\": [\"set_property\", \"contrast\", $CONTRAST] }" | socat - "$SOCKET"
            [ -n "$BRIGHTNESS" ] && echo "{ \"command\": [\"set_property\", \"brightness\", $BRIGHTNESS] }" | socat - "$SOCKET"
            [ -n "$GAMMA" ] && echo "{ \"command\": [\"set_property\", \"gamma\", $GAMMA] }" | socat - "$SOCKET"
            [ -n "$SATURATION" ] && echo "{ \"command\": [\"set_property\", \"saturation\", $SATURATION] }" | socat - "$SOCKET"
            ;;
    esac
    ;;

    "Set Resolution")
        CHOICE=$(printf "1080\n720\n480\n360\nOriginal" | wofi --dmenu --prompt "Set Resolution")

        case "$CHOICE" in
            1080)
                echo '{ "command": ["set_property", "vf", ""] }' | socat - /tmp/mpv-socket
                echo '{ "command": ["set_property", "vf", "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080"] }' | socat - /tmp/mpv-socket
                ;;
            720)
                echo '{ "command": ["set_property", "vf", ""] }' | socat - /tmp/mpv-socket
                echo '{ "command": ["set_property", "vf", "scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720"] }' | socat - /tmp/mpv-socket
                ;;
            480)
                echo '{ "command": ["set_property", "vf", ""] }' | socat - /tmp/mpv-socket
                echo '{ "command": ["set_property", "vf", "scale=854:480:force_original_aspect_ratio=increase,crop=854:480"] }' | socat - /tmp/mpv-socket
                ;;
            360)
                echo '{ "command": ["set_property", "vf", ""] }' | socat - /tmp/mpv-socket
                echo '{ "command": ["set_property", "vf", "scale=640:360:force_original_aspect_ratio=increase,crop=640:360"] }' | socat - /tmp/mpv-socket
                ;;
            Original)
                echo '{ "command": ["set_property", "vf", ""] }' | socat - /tmp/mpv-socket
                ;;
        esac
        ;;




"Video Info")
        ORIG_W=$(echo '{ "command": ["get_property", "video-params/w"] }' | socat - "$SOCKET" | jq -r '.data')
        ORIG_H=$(echo '{ "command": ["get_property", "video-params/h"] }' | socat - "$SOCKET" | jq -r '.data')
        OUT_W=$(echo '{ "command": ["get_property", "dwidth"] }' | socat - "$SOCKET" | jq -r '.data')
        OUT_H=$(echo '{ "command": ["get_property", "dheight"] }' | socat - "$SOCKET" | jq -r '.data')
        FILENAME=$(echo '{ "command": ["get_property", "path"] }' | socat - "$SOCKET" | jq -r '.data')
        FPS_FILE=$(echo '{ "command": ["get_property", "container-fps"] }' | socat - "$SOCKET" | jq -r '.data')
        FPS_PLAY=$(echo '{ "command": ["get_property", "estimated-vf-fps"] }' | socat - "$SOCKET" | jq -r '.data')

        INFO="File: ${FILENAME}\nFPS (File): ${FPS_FILE}\nFPS (Playback): ${FPS_PLAY}\nOriginal: ${ORIG_W}x${ORIG_H}\nOutput: ${OUT_W}x${OUT_H}"
        echo -e "$INFO" | wofi --dmenu --prompt "Video Info" >/dev/null
        ;;

    
    "Status Real-Time")
    status_realtime_menu
    ;;
esac

