#!/usr/bin/env bash

STEP=0.05  # 5%


show_volume_notification() {
    local volume_output
    volume_output=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)

    local volume_value mute_state
    volume_value=$(echo "$volume_output" | awk '{print $2}')
    mute_state=$(echo "$volume_output" | awk '{print $3}')

    if [[ "$mute_state" == "[MUTED]" ]]; then
        notify-send -t 1000 -h string:x-canonical-private-synchronous:volume -h boolean:transient:true "🔇 Muted"
    else
        notify-send -t 1000 -h string:x-canonical-private-synchronous:volume -h boolean:transient:true "🔊 Volume: ${volume_value}"
    fi
}

case "$1" in
    up)
        wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "${STEP}+" && show_volume_notification && wpctl get-volume @DEFAULT_AUDIO_SINK@
        $HOME/File/Script/log/info.sh 3
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "${STEP}-" && show_volume_notification && wpctl get-volume @DEFAULT_AUDIO_SINK@
        $HOME/File/Script/log/info.sh 4
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && show_volume_notification
        $HOME/File/Script/log/info.sh 5
        ;;
    *)
        echo "Usage: $0 up|down|mute"
        exit 1
        ;;
esac

