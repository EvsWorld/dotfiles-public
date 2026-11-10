#!/bin/bash
# PreToolUse hook for Claude Code and Codex CLI.
# Reads the hook JSON payload on stdin, extracts the shell command, and
# blocks (exit 2) if it matches a dangerous pattern. Exit 0 allows.

PAYLOAD=$(cat)
COMMAND=$(printf '%s' "$PAYLOAD" | /usr/bin/jq -r '.tool_input.command // empty' 2>/dev/null)

[ -z "$COMMAND" ] && exit 0

DANGEROUS=(
  'rm -rf[[:space:]]+(/([[:space:]]|$)|~|\$HOME|$HOME)'
  'git([[:space:]]+-[^[:space:]]+|[[:space:]]+--[^[:space:]]+)*[[:space:]]+reset[[:space:]]+--hard'
  '(^|[^a-z])git([[:space:]]+-[^[:space:]]+|[[:space:]]+--[^[:space:]]+)*[[:space:]]+push'
  '(^|[;&|[:space:]])cfg[[:space:]]+push'
  '--git-dir=[^[:space:]]*\.cfg.*push'
  'drop[[:space:]]+table'
  'truncate[[:space:]]+(table[[:space:]]+)?[a-z_]'
  'delete[[:space:]]+from.*where[[:space:]]+1[[:space:]]*=[[:space:]]*1'
  'kubectl[[:space:]]+delete'
  'terraform[[:space:]]+destroy'
  '(^|[[:space:]])mkfs'
  ':\(\)[[:space:]]*\{[[:space:]]*:\|:&[[:space:]]*\};'
)

shopt -s nocasematch
for PATTERN in "${DANGEROUS[@]}"; do
  if [[ "$COMMAND" =~ $PATTERN ]]; then
    echo "BLOCKED by llm-hook-block-dangerous.sh: command matches dangerous pattern '$PATTERN'. Ask the user to run it manually if it is genuinely needed." >&2
    exit 2
  fi
done

exit 0
