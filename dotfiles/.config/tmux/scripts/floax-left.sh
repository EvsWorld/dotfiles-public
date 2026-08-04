#!/bin/bash
# Floax wrapper: always land in the *project pane* (leftmost pane of the Floax
# session's current window) and let only that pane follow the origin directory.
# Scratch panes to its right keep their directory and state.
#
# Directory following lives here, not in the plugin: @floax-change-path is set to
# 'false' in tmux.conf so the plugin skips its own cd, which has no hook for
# "the pane is busy, skip this one". See docs/adr/016-floax-left-pane-is-project-pane.md

FLOAX_DIR="$HOME/.config/tmux/plugins/tmux-floax/scripts"
source "$FLOAX_DIR/utils.sh"

session="${FLOAX_SESSION_NAME:-$DEFAULT_SESSION_NAME}"

# Inside the popup this key is the close toggle — never move focus on the way out.
if [ "$(tmux display-message -p '#{session_name}')" != "$session" ] &&
    tmux has-session -t "$session" 2>/dev/null; then

    origin=$(tmux display -p '#{pane_current_path}')

    # Project pane = smallest pane_left, ties broken by smallest pane_top.
    read -r pane cmd path < <(
        tmux list-panes -t "$session" \
            -F '#{pane_left} #{pane_top} #{pane_id} #{pane_current_command} #{pane_current_path}' |
            sort -k1,1n -k2,2n | head -1 | cut -d' ' -f3-
    )

    tmux select-pane -t "$pane"

    if [ "$path" != "$origin" ]; then
        case "$cmd" in
        zsh | bash | sh | fish)
            # Leading space keeps the cd out of shell history (HIST_IGNORE_SPACE).
            tmux send-keys -R -t "$pane" " cd \"$origin\"" C-m
            ;;
        *)
            tmux display-message -d 1500 "floax: project pane busy ($cmd) — skipped cd"
            ;;
        esac
    fi
fi

exec "$FLOAX_DIR/floax.sh"
