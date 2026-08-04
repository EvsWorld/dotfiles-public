#!/bin/bash

# Insert the current window at a numbered position while preserving the
# relative order of the intervening windows.

target_index="$1"
source_index=$(tmux display-message -p '#{window_index}')
source_id=$(tmux display-message -p '#{window_id}')
session_id=$(tmux display-message -p '#{session_id}')

if [[ "$source_index" == "$target_index" ]]; then
  tmux display-message "Window is already at position $target_index"
  exit 0
fi

if ! tmux list-windows -t "$session_id" -F '#{window_index}' | grep -qx "$target_index"; then
  tmux display-message "No window position $target_index"
  exit 0
fi

if (( source_index > target_index )); then
  tmux move-window -b -s "$source_id" -t "${session_id}:${target_index}"
else
  tmux move-window -a -s "$source_id" -t "${session_id}:${target_index}"
fi

tmux move-window -r -t "$session_id"
