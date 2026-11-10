# ADR 003: Session Restore Policy

## Status

Accepted, amended 2026-09-21.

Originally accepted as "layout-only session restore."
The 2026-09-21 revision below changes the process-restore clause; everything else in the original decision still holds.

## Context

Tmux sessions are used as project-level workspaces. Restoring sessions is useful
because it brings back project names, windows, pane layouts, and working
directories after a tmux server restart.

Fully restoring pane processes is too expensive for this setup. Past restore
behavior relaunched many Neovim, agent, and development-server processes, which
created memory pressure and orphaned `nvim` processes.

> **Superseded 2026-09-21.** The paragraph above is kept as the original
> reasoning, but it conflates two separate mechanisms and no longer describes
> current behavior. The orphaned `nvim` processes were caused by
> `@resurrect-strategy-nvim`, not by process restore. See the revision at the
> end of this document.

`tmux-resurrect` and `tmux-continuum` handle different parts of restoration:

- `tmux-resurrect` saves and restores tmux state.
- `tmux-continuum` periodically calls Resurrect save and can call Resurrect
  restore when the tmux server starts.
- Continuum's auto-save mechanism is triggered through the tmux status line.
  If a theme rewrites `status-right` after Continuum loads, auto-save can stop.

Catppuccin rebuilds `status-right` during plugin loading, so Continuum's normal
status-line auto-save hook can be overwritten unless it is appended after TPM
loads plugins.

## Decision

Use automatic layout restore, relaunch saved pane commands, and restore pane scrollback.
Keep Neovim session restore out of tmux-resurrect entirely.

Configured behavior:

```tmux
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'
set -g @resurrect-processes ':all:'
set -g @resurrect-capture-pane-contents 'on'
# set -g @resurrect-strategy-nvim 'session'
```

The commented `@resurrect-strategy-nvim` line is load-bearing, not incidental.
See the 2026-09-21 revision for why it must stay off.

Also append Continuum's auto-save command to `status-right` after TPM loads
plugins, so Catppuccin cannot remove the save trigger:

```tmux
set -ga status-right "#($HOME/.config/tmux/plugins/tmux-continuum/scripts/continuum_save.sh)"
```

## Consequences

- Tmux server startup restores sessions, windows, panes, layouts, and working
  directories.
- Saved pane commands are relaunched, and pane scrollback is restored.
- Neovim session restoration stays with `auto-session`, never tmux-resurrect.
- Panes with no recorded full command come back as bare shells.
- Continuum auto-save depends on the post-plugin status-right hook remaining in
  the config.

## Rejected Alternatives

- **Layout-only restore (the original decision):** superseded by the 2026-09-21
  revision. Its two objections to process restore no longer hold.
- **Manual restore only:** rejected because automatic restore is useful and, as
  measured below, low risk.
- **Selective process allowlist:** still deferred, and still the right fallback.
  It becomes worth adopting if the saved tool mix ever includes something heavy
  enough that relaunching it by default is a problem.

## Revision 2026-09-21: adopt full process restore

The original decision rejected full process restore on two grounds.
Both have since been invalidated, one by misattribution and one by a mitigation that did not exist when this ADR was written.

### The orphan `nvim` incident was misattributed

The original Context blamed "restore behavior" generally for roughly 18 orphaned `nvim` processes.
The actual cause was `@resurrect-strategy-nvim 'session'` specifically.

`strategies/nvim_session.sh` is purely a command rewrite: with the strategy on, an `nvim` pane restores as `nvim -S`, loading `Session.vim` from the pane's directory.
Because `auto-session` already restores state for that cwd, the two layers both restored, and the double-restore produced the orphans.

That mechanism is independent of `@resurrect-processes` and stays disabled.
`:all:` decides only whether Neovim *launches*; `auto-session` owns buffer state either way.
With `:all:` the pane returns with its cwd and Neovim starts; without it, the pane returns with its cwd and Neovim is started by hand.
The end state is identical, so `:all:` saves a keystroke rather than adding a state-restoration path.

This is the layering rule recorded in `~/.config/docs/adrs/030`: tmux-resurrect owns window structure and working directories, `auto-session` owns Neovim state, and only one layer ever owns Neovim state.

### The memory-pressure objection is now mitigated

This objection was real when written, and remains a genuine property of `:all:`.
It is now bounded automatically.

This ADR was last revised 2026-06-30.
`garbage-day.nvim` landed 2026-07-07 (`21cd861e4`), one week later, and stops LSP clients after 900 seconds unfocused.
Its `focus-events on` dependency is satisfied at `tmux.conf:26`.
On a restore of many Neovim instances at most one is focused, so the rest shed their language servers within fifteen minutes.

Language-server weight is still the variable that matters most here; see `~/.config/docs/adrs/030` on why extra instances are nearly free for markdown repositories and expensive for TypeScript or Rust.

### Blast radius is much smaller than pane count suggests

`scripts/restore.sh:310` filters the save file with `/^pane/ && $11 !~ "^:$"`, so panes with no recorded full command are skipped entirely.
Bare shells cost nothing.

Measured on the 2026-09-20 save: **38 of 137 panes** carry a full command - 17 `nvim`, 12 `lazygit`, 5 `codex`, 3 `claude`, 1 `zsh`.
All are ordinary interactive tools, and none is destructive to re-send.

### Evidence from a real restore

The tmux server restarted 2026-09-16 15:12:39.
The first continuum save afterward, one save interval later, already contained 136 panes across 32 sessions, matching the last pre-restart save.
A cold server without restore would show a single pane.

So `:all:` restored a full workspace at scale, with the nvim strategy off, and the result has been in daily use since.

### Verification on a scratch server (2026-09-21)

The branch-keyed `auto-session` change (`8b8d1b6a0`, 2026-09-20) landed after the 2026-09-16 restore, so it had never been through a server start.
It was exercised on a scratch server with `@resurrect-dir` redirected to a temporary path.

Confirmed:

- `auto-session` restores exactly once, with the branch in the key.
  The notification read `Restored session: $HOME/Projects/the_weather_yesterday (branch: feature/tests)`, with a single set of buffers and no doubled layout.
  This is the ADR 003 failure mode not recurring, tested directly.
- The save filter behaves as described above.
  A two-pane scratch session recorded `panes: 2` and exactly one entry in the relaunch list, `nvim`.
  The bare shell was excluded, confirming the `$11 !~ "^:$"` filter.

Not tested: the final kill-and-restore cycle with resurrect launching Neovim itself.
The gap is small, because with the nvim strategy off resurrect sends plain `nvim`, which is the same command typed by hand in the step that was verified, and the 2026-09-16 restore already exercised that path at scale.

**Re-running this verification safely.**
A scratch server started through the `tmux` shell alias inherits the full config, including continuum's auto-save hook, against the *default* `@resurrect-dir`.
Override `@resurrect-dir` to a temporary path before saving, or the scratch server can overwrite the real snapshot.
Note also that tmux 3.6a loads multiple `-f` files in sequence rather than letting the last one win, so passing `-f` does not by itself displace the alias's config.
Tracked in `~/Projects/todos/prevent-scratch-tmux-servers-clobbering-resurrect-snapshot.md`.

### Known costs that remain

- Restore calls `tmux switch-client` once per restored pane, so the client jumps
  around during restore and lands on an arbitrary session.
- A bare `codex resume` pane opens an interactive picker and waits for input.
  Earlier this was bare `claude --resume`; the specific tool changes as the mix does.
- `~/.local/share/tmux/resurrect/` grows without bound and resurrect does not
  prune it. Scrollback capture makes this faster. Tracked separately in
  `~/Projects/todos/prune-tmux-resurrect-save-directory.md`.

Two costs anticipated in 2026-08 did not materialize.
Despite `history-limit 50000` and `@resurrect-pane-contents-area` defaulting to `full`, `pane_contents.tar.gz` is around 2 MB and saves ran on schedule for 31 days.
If saves ever do get slow, `set -g @resurrect-pane-contents-area 'visible'` is the mitigation.

### Note on process name matching

Restore matches on `pane_full_command`, not `pane_current_command` (`scripts/process_restore_helpers.sh:74-80`).
This matters because Claude Code reports a version string as its `pane_current_command`.
No shim or wrapper script is needed for it to restore correctly.
