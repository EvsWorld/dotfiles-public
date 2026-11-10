# ADR 019: Remove tmux-nerd-font-window-name; a Window Name Cannot Describe Several Panes

## Status

Accepted (2026-08-21)

Supersedes [ADR 018](018-enable-automatic-rename-for-nerd-font-window-icons.md).

## Context

ADR 018 adopted `joshmedeski/tmux-nerd-font-window-name` to replace a status bar
of `zsh`, `zsh`, `node`, `zsh` with per-window Nerd Font glyphs, and enabled
`automatic-rename` to do it.

In use the labels turned out to be actively misleading. tmux derives
`automatic-rename-format` from the window's **active pane**, so
`pane_current_command` is whichever pane was focused last. Windows here almost
always hold several panes, typically an editor beside one or more agent CLIs, so
the icon changed as focus moved and described one pane out of several. A window
running nvim and Claude side by side would show either, depending on nothing
meaningful.

This is a property of `automatic-rename` itself, not of the plugin. No plugin
setting changes it, because tmux never offers the format anything but the active
pane. `multi-pane-icon` only appends a "this window is split" marker; it does not
make the label represent the window's contents.

## Decision

Remove the plugin and everything added for it. Restore `automatic-rename off`.
Window names stay manual, set with `Prefix+r`.

## Rationale / Alternatives Considered

- **Keep it with `multi-pane-icon` set.** Rejected. It marks a window as split
  without fixing which pane the icon describes, so the label is still wrong,
  just annotated.
- **Keep it and rely on manual names for multi-pane windows.** Rejected: that is
  the majority of windows, so the plugin would be decoration on the minority
  while adding a per-window job on every status refresh.
- **Disable rather than remove, leaving the config commented out.** Rejected on
  request. The reasoning belongs in this ADR, not in commented-out `tmux.conf`
  blocks; git history holds the implementation if it is ever wanted back.
- **A custom `automatic-rename-format` summarising every pane.** Not attempted.
  tmux formats cannot iterate a window's panes, so this needs an external script
  per window per refresh, which is the cost profile rejected in ADR 018 and the
  cause of the earlier sidebar load spike.

## Files Touched

- `tmux.conf` - `@plugin` line, config-file option, and the `automatic-rename on`
  block removed; the file is now identical to its pre-018 state.
- `tmux-nerd-font-window-name.yml` - deleted.
- `README.md` - plugin entry removed, behavior note restored to "Automatic
  window renaming disabled (manual naming encouraged)".
- `docs/adr/018` - marked superseded.

## Consequences

The plugin checkout stays in `plugins/tmux-nerd-font-window-name` until TPM's
`Prefix+Alt+u` prunes it; it is no longer sourced.

Options already applied to a running tmux server outlive the config change.
`automatic-rename-format` is still set globally, and the plugin explicitly set
`automatic-rename on` per window (`tmux set-option -w`) for every window it
renamed, which a global `off` does not override. Those windows keep their icon
names, some containing literal `#[fg=...]` styling, until reset or until the
server restarts.

Backing that out of a running server has a trap. Unsetting
`automatic-rename-format` while windows still carry the plugin's per-window
`automatic-rename on` does not stop renaming: tmux falls back to its built-in
default of `#{pane_current_command}` and immediately renames every such window.
That happened here, silently rewriting all 73 windows between two runs of the
cleanup a minute apart. Dropping the per-window override then freezes whatever
name that produced, which for Claude Code is a bare version string, leaving
seven windows permanently called `2.1.220`.

The working order is: rename each affected window to something intended, then
`tmux set-option -uw -t <window> automatic-rename` to drop the override. Match
affected windows on names containing `#[` or non-ASCII glyphs, plus bare semver
names, so hand-named windows are left alone.

The original complaint from ADR 018 stands: the status bar is again a row of
`zsh`. Manual naming remains the answer, and is a better fit, because a
hand-written name can describe what the whole window is *for*, which is exactly
what an active-pane-derived label cannot do.
