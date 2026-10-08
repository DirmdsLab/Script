#!/usr/bin/env bash

SESSION="grid"
WINDOW="0"

tmux kill-session -t "$SESSION" 2>/dev/null

tmux new-session -d -s "$SESSION"

# Create 4 panes
tmux split-window -h -t "$SESSION:$WINDOW"
tmux split-window -v -t "$SESSION:$WINDOW\.0"
tmux split-window -v -t "$SESSION:$WINDOW\.1"

# Arrange panes in a 2x2 grid
tmux select-layout -t "$SESSION:$WINDOW" tiled

# Check pane order
tmux list-panes -t "$SESSION:$WINDOW"

# Set pane content based on index
tmux send-keys -t "$SESSION:$WINDOW\.0" "clear && echo 'panel 1'" C-m
tmux send-keys -t "$SESSION:$WINDOW\.1" "clear && echo 'panel 2'" C-m
tmux send-keys -t "$SESSION:$WINDOW\.2" "clear && echo 'panel 3'" C-m
tmux send-keys -t "$SESSION:$WINDOW\.3" "clear && echo 'panel 4'" C-m

# Focus on the top-left pane
tmux select-pane -t "$SESSION:$WINDOW\.0"

tmux attach-session -t "$SESSION"