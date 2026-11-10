#!/bin/bash
# SessionEnd hook for Claude Code.
# Logs when a session ends with reason and metadata.

TOOL="${1:-unknown}"
LOG_FILE="$HOME/.claude/session_end.log"

PAYLOAD=$(cat)
SESSION_ID=$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.session_id // "?"' 2>/dev/null)
REASON=$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.reason // "?"' 2>/dev/null)
CWD=$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.cwd // "?"' 2>/dev/null)
TRANSCRIPT=$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.transcript_path // ""' 2>/dev/null)

SESSION_NAME="?"
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  SESSION_NAME=$(tail -1 "$TRANSCRIPT" 2>/dev/null | /usr/bin/jq -r '.lastPrompt // "?"' 2>/dev/null)
fi

if [ -z "$SESSION_NAME" ] || [ "$SESSION_NAME" = "?" ] && [ -n "${TMUX:-}" ]; then
  SESSION_NAME=$(tmux display-message -p '#S' 2>/dev/null)
fi
SESSION_NAME="${SESSION_NAME:-?}"

MSG=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  LAST_ASSISTANT=$(tac "$TRANSCRIPT" 2>/dev/null | grep -m1 '"role":"assistant"' 2>/dev/null)
  MSG=$(printf '%s' "$LAST_ASSISTANT" | /usr/bin/jq -r '.message.content[0].text // ""' 2>/dev/null | \
    tr '\n' ' ' | cut -c1-600)
fi

echo "$(date '+%Y-%m-%d %H:%M') | tool=$TOOL | session=$SESSION_NAME | id=$SESSION_ID | reason=$REASON | cwd=$CWD | message=$MSG" >> "$LOG_FILE"

exit 0
