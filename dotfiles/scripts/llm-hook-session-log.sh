#!/bin/bash
# Stop hook for Claude Code and Codex CLI.
# Appends a one-line session record to a shared history log.
# Usage: llm-hook-session-log.sh <tool-name>   (payload JSON on stdin)

TOOL="${1:-unknown}"
LOG_FILE="$HOME/.claude/session_history.log"

PAYLOAD=$(cat)
CWD=$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.cwd // "?"' 2>/dev/null)
SESSION_NAME=$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.session_name // .session_title // .title // empty' 2>/dev/null)
SESSION_ID=$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.session_id // .conversation_id // .thread_id // "?"' 2>/dev/null)
EVENT=$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.hook_event_name // .event // "?"' 2>/dev/null)

if [ -z "$SESSION_NAME" ] && [ -n "${TMUX:-}" ]; then
  SESSION_NAME=$(tmux display-message -p '#S' 2>/dev/null)
fi
SESSION_NAME="${SESSION_NAME:-?}"

MSG=$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.last_assistant_message // ""' 2>/dev/null \
  | tr '\n' ' ' | cut -c1-300)

echo "$(date '+%Y-%m-%d %H:%M') | tool=$TOOL | session=$SESSION_NAME | id=$SESSION_ID | event=$EVENT | cwd=$CWD | message=$MSG" >> "$LOG_FILE"

exit 0
