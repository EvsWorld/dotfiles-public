# ADR 008: No-Prefix `Ctrl+/` Opens Copy-Mode Search

## Status

Accepted (2026-07-02)

## Context

The desired search flow is a single keypress from a normal pane: press `Ctrl+/`,
enter tmux copy mode, and immediately open the backward-search prompt. This is
different from the existing copy-mode `/` binding, which only works after copy
mode is already active.

There was also a key-name mismatch during implementation. A prefix-table binding
worked in `tmux list-keys`, but it required `Prefix` first. The intended behavior
belongs in the `root` table, which tmux config expresses with `bind -n`.

Finally, terminals commonly encode physical `Ctrl+/` as `Ctrl+_`. To keep the
mapping stable across terminal/key encoding differences, both tmux key names need
to trigger the same command.

## Decision

Bind both `C-/` and `C-_` in the root table:

```tmux
bind -n C-/ copy-mode \; command-prompt -p "(search up)" "send-keys -X search-backward \"%%%\""
bind -n C-_ copy-mode \; command-prompt -p "(search up)" "send-keys -X search-backward \"%%%\""
```

The existing copy-mode-vi `/` binding remains in place for searching again after
copy mode is already active.

## Rationale / Alternatives Considered

- **Prefix binding (`bind C-/`).** Rejected: it requires `Prefix` first, which is
  not the desired workflow.
- **Only bind `C-/`.** Rejected: it may fail in terminals that report the same
  physical key as `C-_`.
- **Only bind `C-_`.** Rejected: `tmux list-keys` can represent `C-/` directly,
  and keeping both names documents the compatibility intent.

## Files Touched

- `bindings.conf` — added the root-table `C-/` and `C-_` search bindings.
- `README.md` — documents `Ctrl+/` as the no-prefix search entry point.

## Consequences

- `Ctrl+/` from a normal pane enters copy mode and opens the backward-search
  prompt.
- `C-_` should stay even if `C-/` appears to work, because it is the compatibility
  binding for terminals that encode physical `Ctrl+/` differently.
- The normal in-copy-mode `/` search key still works independently.

## Useful Commands

```bash
tmux source-file ~/.config/tmux/tmux.conf
tmux list-keys -T root | grep -E 'C-/|C-_'
tmux list-keys -T copy-mode-vi | grep 'search-backward'
```
