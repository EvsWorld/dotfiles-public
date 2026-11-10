#!/usr/bin/env bash
# Runs `select-layout $1` in the current window, then restores the
# tmux-agent-sidebar pane (pane option @pane_role == sidebar) back to its
# pre-layout width. select-layout has no "skip this pane" concept, so this
# is what keeps the sidebar column fixed across equalize/even-* bindings.
set -euo pipefail

layout_arg="$1"

sidebar_id=""
sidebar_width=""
while read -r pane_id pane_width pane_role; do
  if [[ "$pane_role" == "sidebar" ]]; then
    sidebar_id="$pane_id"
    sidebar_width="$pane_width"
    break
  fi
done < <(tmux list-panes -F "#{pane_id} #{pane_width} #{@pane_role}")

tmux select-layout "$layout_arg"

if [[ -n "$sidebar_id" ]]; then
  tmux resize-pane -t "$sidebar_id" -x "$sidebar_width"

  # resize-pane -x only trades space with the pane immediately adjacent to
  # the sidebar, so the rest of the columns are left at their stale
  # just-evened width. Rebalance the remaining columns explicitly.
  columns=()
  while read -r pane_id pane_left pane_role; do
    [[ "$pane_role" == "sidebar" ]] && continue
    already_seen=0
    for c in "${columns[@]}"; do
      [[ "${c%%:*}" == "$pane_left" ]] && already_seen=1 && break
    done
    [[ "$already_seen" -eq 0 ]] && columns+=("$pane_left:$pane_id")
  done < <(tmux list-panes -F "#{pane_id} #{pane_left} #{@pane_role}" | sort -k2 -n)

  num_columns=${#columns[@]}
  if (( num_columns >= 2 )); then
    window_width=$(tmux display-message -p '#{window_width}')
    avail=$(( window_width - sidebar_width - num_columns ))
    target=$(( avail / num_columns ))
    remainder=$(( avail % num_columns ))

    for ((i = 0; i < num_columns - 1; i++)); do
      width=$target
      (( i < remainder )) && width=$(( width + 1 ))
      pane_id="${columns[i]#*:}"
      tmux resize-pane -t "$pane_id" -x "$width"
    done
  fi
fi
