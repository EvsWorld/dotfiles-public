#!/bin/bash
# which-key for tmux — two front-ends over one source of truth.
#
# Descriptions live on the bindings themselves as `bind -N "note"` in
# bindings.conf. Nothing here hand-lists keys; both front-ends read them back
# out of the running server via `list-keys -N`.
#
#   keys.sh menu <table>      display-menu of a table  (press the real key)
#   keys.sh find [tables...]  fzf palette across tables (search a description)
#   keys.sh exec <table> <key>  run one binding — the shared execution routine
#
# Neither front-end reconstructs a command; both call `exec`, which resolves it
# from tmux at execution time. That keeps `\;` command chains from being
# re-quoted through a second parser.

set -uo pipefail

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# Tables searched by `find` when none are named.
DEFAULT_TABLES=(root prefix window-ops window-ops-move window-ops-reorder copy-mode-vi)

# --- shared parsing -------------------------------------------------------
#
# `list-keys -T <table>` prints `bind-key [flags] -T <table> <key> <command...>`.
# Locate the `-T` token rather than assuming a fixed field offset — a leading
# `-r` shifts everything (`bind-key -r -T root M-H ...`).
#
# The two list-keys forms escape keys differently: the default form prints
# \" \' \; \$ while the -N form prints them bare. Strip the leading backslash so
# keys join across forms, otherwise those bindings silently vanish from the list.
awk_split_bind='
  function normalize(k) { sub(/^\\/, "", k); return k }
  {
    t = 0
    for (i = 1; i <= NF; i++) if ($i == "-T") { t = i; break }
    if (t == 0) next
    key = normalize($(t + 2))
    cmd = ""
    for (i = t + 3; i <= NF; i++) cmd = cmd (cmd == "" ? "" : " ") $i
  }
'

# key<TAB>command for every binding in a table.
table_commands() {
  tmux list-keys -T "$1" 2>/dev/null | awk "$awk_split_bind"'{ print key "\t" cmd }'
}

# key<TAB>note for every *described* binding in a table. Always pass -T: a bare
# `list-keys -N` covers only root and prefix, and prepends the prefix string.
table_notes() {
  tmux list-keys -N -T "$1" 2>/dev/null |
    sed -E 's/^([^ ]+) +(.*)$/\1\t\2/'
}

# key<TAB>description for a table, falling back to the command text when a
# binding has no note yet. Without the fallback an unannotated table renders as
# rows of blank descriptions — nothing to read, nothing to search.
#
# The two streams are tagged rather than joined with `NR == FNR`: that idiom
# breaks when the notes stream is empty, because NR and FNR then stay equal for
# the whole second stream and every command row is silently eaten as a note.
# An unannotated table is exactly the starting state here.
#
# Mouse events are dropped: `root` and `copy-mode-vi` carry ~17 and ~7 of them,
# they cannot be invoked from a keyboard-shortcut list, and their tmux built-in
# definitions are multi-line `if-shell` blobs that would swamp everything else.
# Long fallback text is capped for the same reason — a few root bindings inline
# the whole vim-detection `ps | grep` pipeline.
table_described() {
  local table="$1"
  {
    table_notes "$table" | sed 's/^/N\t/'
    table_commands "$table" | sed 's/^/C\t/'
  } | awk -F'\t' -v OFS='\t' '
    $2 ~ /(Mouse|Wheel|DoubleClick|TripleClick)/ { next }   # unanchored: M-MouseDown3Pane too
    $1 == "N" { note[$2] = $3; next }
    $1 == "C" {
      d = ($2 in note && note[$2] != "") ? note[$2] : $3
      if (length(d) > 76) d = substr(d, 1, 73) "..."
      print $2, d
    }
  ' | order_by_target "$table"
}

# `list-keys` sorts by ASCII, which gets two of this config's conventions wrong:
#
#   digits    `0` means *ten* (window 10, position 10), so it belongs after `9`,
#             not above `1`.
#   harpoon   `j k l : '` mean windows 1-5, but `:` (0x3a) sorts before `j`.
#
# Reorder each of those groups by what the key *means*, in place: a group's rows
# stay in the slots tmux gave them, and every other row is untouched.
#
# Only applied to the tables where those keys carry that meaning. In
# `copy-mode-vi` (98 bindings, mostly tmux built-ins) `j`/`k`/`l`/`:` are cursor
# movement and goto-line, and digits are repeat counts — reordering them by
# window number would be nonsense. `window-ops` is left alone too: its `j`/`k`/`l`
# are pane swaps, and tmux's order is already right for them.
order_by_target() {
  case "$1" in
    window-ops)
      awk -F'\t' '
        { line[NR] = $0; key[NR] = tolower($2) }
        END {
          n = NR
          for (i = 2; i <= n; i++) {
            v = key[i]; t = line[i]; b = i - 1
            while (b >= 1 && key[b] > v) { key[b+1] = key[b]; line[b+1] = line[b]; b-- }
            key[b+1] = v; line[b+1] = t
          }
          for (i = 1; i <= n; i++) print line[i]
        }
      '
      return
      ;;
    prefix|window-ops-move|window-ops-reorder) ;;
    *) cat; return ;;
  esac
  awk -F'\t' '
    function rank(k) {
      if (k ~ /^[0-9]$/) return (k == "0" ? 10 : k + 0)
      return (k == "j") ? 1 : (k == "k") ? 2 : (k == "l") ? 3 : (k == ":") ? 4 : 5
    }
    function group(k) {
      if (k ~ /^[0-9]$/) return "digit"
      if (k == "j" || k == "k" || k == "l" || k == ":" || k == sprintf("%c", 39)) return "harpoon"
      return ""
    }
    { line[NR] = $0
      g = group($1)
      if (g != "") { n[g]++; at[g, n[g]] = NR; val[g, n[g]] = rank($1); txt[g, n[g]] = $0 }
    }
    END {
      split("digit harpoon", groups, " ")
      for (gi in groups) {
        g = groups[gi]
        for (a = 2; a <= n[g]; a++) {              # insertion sort; n <= 10
          v = val[g, a]; t = txt[g, a]; b = a - 1
          while (b >= 1 && val[g, b] > v) {
            val[g, b+1] = val[g, b]; txt[g, b+1] = txt[g, b]; b--
          }
          val[g, b+1] = v; txt[g, b+1] = t
        }
        for (i = 1; i <= n[g]; i++) line[at[g, i]] = txt[g, i]
      }
      for (i = 1; i <= NR; i++) print line[i]
    }
  '
}

# --- exec: the single execution routine ------------------------------------
cmd_exec() {
  local table="$1" key="$2" cmd
  cmd=$(table_commands "$table" | awk -F'\t' -v k="$key" '$1 == k { print $2; exit }')

  if [ -z "$cmd" ]; then
    tmux display-message "keys.sh: no binding for '$key' in table '$table'"
    return 1
  fi

  # copy-mode-vi bindings are `send-keys -X …`, which do nothing unless the pane
  # is already in copy mode. Enter it first so these are runnable from the
  # palette rather than reference-only.
  if [ "$table" = "copy-mode-vi" ] &&
     [ "$(tmux display-message -p '#{pane_in_mode}')" = "0" ]; then
    tmux copy-mode
  fi

  # Let *tmux* parse this, not bash. `list-keys` output is escaped for tmux's
  # own parser: a leading `~` is emitted as `\~`, and bash's double-quote rules
  # keep that backslash, so `eval` handed /bin/sh a literal `\~/...` path and
  # the binding died with 127. `run-shell -C` runs the string as a tmux command,
  # which resolves `\~` back to `~`.
  #
  # The one thing -C does not do is treat `\;` as a command separator — it reads
  # it as a literal argument, which breaks multi-command binds like
  # `swap-pane … \; display-message …`. Unescape those to plain `;` first.
  tmux run-shell -C "${cmd//\\;/;}"
}

# --- menu: the which-key front-end -----------------------------------------
cmd_menu() {
  local table="$1" pane key desc
  pane=$(tmux display-message -p '#{pane_id}')

  local args=() skipped=0
  while IFS=$'\t' read -r key desc; do
    [ -z "$key" ] && continue
    # Use double quotes for the shell command. This keeps quote keys valid menu
    # shortcuts—for example, `'` for window 5—while still passing the key as
    # one argument to `exec`.
    args+=("$desc" "$key" "run-shell -b \"$SELF exec $table \\\"$key\\\"\"")
  done < <(table_described "$table")

  if [ ${#args[@]} -eq 0 ]; then
    tmux display-message "keys.sh: no bindings in table '$table'"
    return 1
  fi

  # -t targets the invoking pane so menu items act where they were called from.
  tmux display-menu -t "$pane" -T "#[align=centre] $table " -x C -y C "${args[@]}"
}

# --- find: the palette front-end -------------------------------------------
cmd_find() {
  local tables=("$@")
  [ ${#tables[@]} -eq 0 ] && tables=("${DEFAULT_TABLES[@]}")

  local rows table key desc sel
  rows=""
  for table in "${tables[@]}"; do
    while IFS=$'\t' read -r key desc; do
      [ -z "$key" ] && continue
      # Displayed column first, then the fields exec needs, hidden from fzf.
      rows+=$(printf '%-20s %-10s %s\t%s\t%s' "$table" "$key" "$desc" "$table" "$key")$'\n'
    done < <(table_described "$table")
  done

  [ -z "$rows" ] && { tmux display-message "keys.sh: no bindings found"; return 1; }

  sel=$(printf '%s' "$rows" | fzf --tmux center,70%,60% \
    --delimiter=$'\t' --with-nth=1 \
    --prompt='keys: ' --border-label=' tmux keys ' \
    --header='Enter = run   Esc = cancel')

  [ -z "$sel" ] && return 0
  cmd_exec "$(printf '%s' "$sel" | cut -f2)" "$(printf '%s' "$sel" | cut -f3)"
}

# --- dispatch ---------------------------------------------------------------
case "${1:-}" in
  menu) shift; cmd_menu "${1:?usage: keys.sh menu <table>}" ;;
  find) shift; cmd_find "$@" ;;
  exec) shift; cmd_exec "${1:?usage: keys.sh exec <table> <key>}" "${2:?usage: keys.sh exec <table> <key>}" ;;
  *)    echo "usage: keys.sh {menu <table>|find [tables...]|exec <table> <key>}" >&2; exit 2 ;;
esac
