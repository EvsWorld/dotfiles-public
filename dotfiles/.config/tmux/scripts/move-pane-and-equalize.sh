#!/bin/bash
# Move pane to target window and equalize remaining panes in source window

# Capture the source window ID before moving
source_window=$(tmux display-message -p "#{window_id}")

# Move the pane to the target window (passed as argument) and follow it.
tmux move-pane -h -t ":$1"

# Equalize the remaining panes in the source window — but only if it still
# exists. Moving the last pane out of a window closes it, and select-layout
# on a gone window exits 1, which tmux then reports as a "returned 1" error.
if tmux list-windows -F '#{window_id}' | grep -qx "$source_window"; then
  tmux select-layout -t "$source_window" -E
fi
