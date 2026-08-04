#!/bin/bash
# Move pane to target window and equalize remaining panes in source window

# Capture the source window ID before moving
source_window=$(tmux display-message -p "#{window_id}")

# Move the pane to the target window (passed as argument) and follow it.
tmux move-pane -h -t ":$1"

# Equalize the remaining panes in the source window
tmux select-layout -t "$source_window" -E
