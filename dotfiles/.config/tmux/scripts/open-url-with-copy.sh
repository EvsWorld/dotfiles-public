#!/bin/bash
# Custom URL handler for tmux-fzf-url plugin.
# Copies the selected URL to clipboard and opens it in Firefox.
# Used by prefix+o binding via @fzf-url-open in tmux.conf.

url="$1"

if [[ -z "$url" ]]; then
  echo "Error: no URL provided" >&2
  exit 1
fi

# Copy to macOS clipboard
echo -n "$url" | pbcopy

# Open in Firefox (nohup detaches from tmux so pane remains active)
nohup open -a Firefox "$url" &>/dev/null &
