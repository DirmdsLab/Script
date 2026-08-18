#!/usr/bin/env bash

SESSION="grid"
WINDOW="0"

tmux kill-session -t "$SESSION" 2>/dev/null

tmux new-session -d -s "$SESSION"

# buat 4 pane
tmux split-window -h -t "$SESSION:$WINDOW"
tmux split-window -v -t "$SESSION:$WINDOW.0"
tmux split-window -v -t "$SESSION:$WINDOW.1"

# rapikan jadi 2x2
tmux select-layout -t "$SESSION:$WINDOW" tiled

# cek urutan pane
tmux list-panes -t "$SESSION:$WINDOW"

# isi pane berdasarkan index
tmux send-keys -t "$SESSION:$WINDOW.0" "clear && echo 'panel 1'" C-m
tmux send-keys -t "$SESSION:$WINDOW.1" "clear && echo 'panel 2'" C-m
tmux send-keys -t "$SESSION:$WINDOW.2" "clear && echo 'panel 3'" C-m
tmux send-keys -t "$SESSION:$WINDOW.3" "clear && echo 'panel 4'" C-m

# fokus kiri atas
tmux select-pane -t "$SESSION:$WINDOW.0"

tmux attach-session -t "$SESSION"