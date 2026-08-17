#!/usr/bin/env bash

SOCKET="/tmp/mpv-socket"
CURRENT_MODE=""  

while true; do
    ACTIVE=$(hyprctl activewindow -j | jq -r '.class')

    if [ "$ACTIVE" != "null" ] && [ -n "$ACTIVE" ]; then
       
        if [ "$CURRENT_MODE" != "pause" ]; then
            echo '{ "command": ["set_property", "pause", true] }' | socat - $SOCKET
            CURRENT_MODE="pause"
            echo "pause"
        fi
    else
        
        if [ "$CURRENT_MODE" != "play" ]; then
            echo '{ "command": ["set_property", "pause", false] }' | socat - $SOCKET
            CURRENT_MODE="play"
            echo "play"
        fi
    fi

    sleep 2
done
