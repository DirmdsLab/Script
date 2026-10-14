#!/usr/bin/env bash

LOG_FILE="/tmp/logscript-uwu.log"

log() {
    echo "$1" | tee -a "$LOG_FILE"
    notify-send "UwU Script" "$1"
}

sleep 1

# Open Terminal Super + T
log "Open Terminal"
ydotool key 125:1 20:1 20:0 125:0

sleep 1

# Type Tmux command
log "Typing Tmux"
ydotool type -- "new-attach UwU"

sleep 1

# Press Enter
log "Enter"
ydotool key 28:1 28:0

sleep 1

# Type Float Setup command
log "Float Setup"
ydotool type -- "Float-Setup"

sleep 1

# Press Enter
log "Enter"
ydotool key 28:1 28:0

sleep 4

# Press Super + D
log "Super + D"
ydotool key 125:1 32:1 32:0 125:0

sleep 1

# Type Idle command
log "Idle"
ydotool type 'echo setupstay'

sleep 2

ydotool key 106:1 106:0

sleep 1

# Press Enter
log "Enter"
ydotool key 28:1 28:0

sleep 1

# Open new Tmux tab
log "Open new Tmux tab"
ydotool key 29:1 48:1 48:0 29:0
sleep 0.5
ydotool type "c"

sleep 1

# Type ADB directory command
log "Type ADB directory command"
ydotool type -- "cd $HOME/File/Script/adb/ && ls"

sleep 5

# Press Enter
log "Enter"
ydotool key 28:1 28:0

sleep 1

# Open new Tmux tab
log "Open new Tmux tab"
ydotool key 29:1 48:1 48:0 29:0
sleep 0.5
ydotool type "c"

sleep 1

# Open another terminal tab
log "Open another terminal tab"
ydotool key 29:1 42:1 20:1 20:0 42:0 29:0

sleep 1

# Press Super + S
log "Super + S"
ydotool key 125:1 31:1 31:0 125:0

sleep 1

# Press Super + Ctrl + F
log "Super + Ctrl + F"
ydotool key 125:1 29:1 33:1 33:0 29:0 125:0

sleep 5

# Press Super + E
log "Super + E"
ydotool key 125:1 18:1 18:0 125:0

sleep 1

# Press Super + Ctrl + E
log "Super + Ctrl + E"
ydotool key 125:1 29:1 18:1 18:0 29:0 125:0

sleep 3

# Press Super + C
log "Super + C"

ydotool key 125:1 46:1 46:0 125:0

sleep 1

# vs code 
log "Super + Ctrl + C"

ydotool key 125:1 29:1 46:1 46:0 29:0 125:0

sleep 5

# Press Super + W
log "Super + W"
ydotool key 125:1 17:1 17:0 125:0

sleep 1

# Press Super + D
log "Super + D"
ydotool key 125:1 32:1 32:0 125:0

sleep 1

log "Done"