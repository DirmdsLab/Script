#!/usr/bin/env bash

set -uo pipefail

# IPC socket paths
MPV_SOCKET="/tmp/mpv-socket"
HYPRLAND_SOCKET="${XDG_RUNTIME_DIR:?}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:?}/.socket2.sock"

# Track the current playback mode
CURRENT_MODE=""

# Update playback only when the mode changes
set_playback_mode() {
    local new_mode="$1"
    local pause_value

    [[ "$new_mode" == "$CURRENT_MODE" ]] && return 0

    if [[ "$new_mode" == "pause" ]]; then
        pause_value="true"
    else
        pause_value="false"
    fi

    if printf '{"command":["set_property","pause",%s]}\n' "$pause_value" |
        socat - "UNIX-CONNECT:$MPV_SOCKET" >/dev/null 2>&1; then

        CURRENT_MODE="$new_mode"
        printf '%s\n' "$CURRENT_MODE"
    else
        printf 'Failed to communicate with mpvpaper IPC socket\n' >&2
        return 1
    fi
}

# Synchronize playback with the active window
sync_playback_mode() {
    local window_class

    if ! window_class=$(hyprctl activewindow -j | jq -r '.class // empty'); then
        printf 'Failed to query the active window\n' >&2
        return 1
    fi

    if [[ -n "$window_class" ]]; then
        set_playback_mode "pause"
    else
        set_playback_mode "play"
    fi
}

# Verify the Hyprland event socket
if [[ ! -S "$HYPRLAND_SOCKET" ]]; then
    printf 'Hyprland event socket not found: %s\n' "$HYPRLAND_SOCKET" >&2
    exit 1
fi

# Wait for mpvpaper IPC during startup
for ((attempt = 0; attempt < 50; attempt++)); do
    [[ -S "$MPV_SOCKET" ]] && break
    sleep 0.1
done

if [[ ! -S "$MPV_SOCKET" ]]; then
    printf 'MPV IPC socket not found: %s\n' "$MPV_SOCKET" >&2
    exit 1
fi

# Listen for Hyprland events
socat -U - "UNIX-CONNECT:$HYPRLAND_SOCKET" | {

    # Synchronize initial playback state
    sync_playback_mode

    while IFS= read -r event; do
        case "$event" in
            activewindowv2\>\>*)
                window_address="${event#activewindowv2>>}"

                if [[ -n "$window_address" && "$window_address" != "0x0" ]]; then
                    set_playback_mode "pause"
                else
                    set_playback_mode "play"
                fi
                ;;

            closewindow\>\>*|openwindow\>\>*|workspacev2\>\>*|focusedmonv2\>\>*|activespecialv2\>\>*)
                sync_playback_mode
                ;;
        esac
    done
}