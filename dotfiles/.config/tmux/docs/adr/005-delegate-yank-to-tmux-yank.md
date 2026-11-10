# ADR 005: Delegate Copy-Mode Yank Keys to tmux-yank via `@yank_action`

## Status

Accepted

## Context

After [ADR 004](004-single-bindings-file.md) moved every keybinding into
`bindings.conf`, the copy-mode yank keys were maintained by hand there:

```tmux
bind-key -T copy-mode-vi y send-keys -X copy-pipe 'pbcopy'                 # stay
bind-key -T copy-mode-vi Y send-keys -X copy-pipe-and-cancel 'pbcopy'      # copy + exit
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe 'pbcopy'
bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe 'pbcopy'
# plus a dead line: copy-mode-vi MouseDragEnd1Pane … copy-selection (shadowed)
```

Reading the tmux-yank source (`plugins/tmux-yank/yank.tmux`, `scripts/helpers.sh`)
showed these were redundant with what the plugin already produces:

- On macOS tmux-yank's copy command resolves to **`pbcopy`** (helpers.sh:143-147) —
  the same clipboard target; `pbcopy` replaces, so it never appends.
- tmux-yank binds `y` and `MouseDragEnd1Pane` in both `copy-mode-vi` and `copy-mode`
  (mouse on by default), using the `@yank_action` option (default
  `copy-pipe-and-cancel` = copy then exit).
- Setting `@yank_action 'copy-pipe'` makes tmux-yank's `y` and mouse **stay** in copy
  mode and pipe to `pbcopy` — exactly the manual `y`/mouse behavior.

The one thing tmux-yank cannot express is our `Y`: tmux-yank's `Y` is *paste* (put),
whereas we want `Y` = copy-and-exit.

## Decision

Delegate the yank keys to tmux-yank and keep only the override the plugin can't
express:

- Add `set -g @yank_action 'copy-pipe'` in `tmux.conf` (plugin-options area, before
  `run tpm`). tmux-yank now provides `y` and mouse-drag copy (both tables): copy to
  `pbcopy`, stay in copy mode.
- Remove the manual `y`, both `MouseDragEnd1Pane` overrides, and the dead
  `copy-selection` line from `bindings.conf`.
- Keep exactly one override in `bindings.conf`:
  `bind-key -T copy-mode-vi Y send-keys -X copy-pipe-and-cancel 'pbcopy'`. Because
  `bindings.conf` loads after TPM, it still wins over tmux-yank's paste-`Y`.

Non-yank copy-mode keys (`v`, `H`, `L`, `C-c`, `Escape`, `/`, `C-v`, `C-d`/`C-u`,
wheel scroll) are untouched — tmux-yank never bound them.

## Rationale / Alternatives Considered

- **Keep everything explicit (only delete the dead line).** Fully honors ADR 004's
  "one obvious place, no plugin reasoning." Rejected in favor of removing four
  hand-maintained lines that merely re-implement the plugin's default on this machine.
- **Fully delegate, including `Y`.** Would make `Y` paste instead of copy-and-exit —
  a behavior change we did not want. Rejected; `Y` stays overridden.

This is a deliberate, scoped exception to ADR 004: copy-mode `y`/mouse behavior is now
*implicit* from tmux-yank + `@yank_action` rather than spelled out in `bindings.conf`.
The tradeoff — fewer lines vs. everything-explicit — was taken knowingly for the yank
keys only. Cross-referencing comments in `tmux.conf` and `bindings.conf` point at each
other so the behavior stays discoverable.

## Files Touched

- `tmux.conf` — added `set -g @yank_action 'copy-pipe'` with an explanatory comment.
- `bindings.conf` — removed the manual `y`, both `MouseDragEnd1Pane`, and the dead
  `copy-selection` lines; kept `Y`; replaced the block with a comment describing where
  `y`/mouse now come from.

## Consequences

- `bindings.conf` no longer hand-maintains the yank keys; changing yank behavior is now
  a one-line `@yank_action` edit.
- Effective behavior for the keys actually used under `mode-keys vi` is unchanged:
  `y` copies and stays, `Y` copies and exits, mouse-drag copies, none append.
- Verified with the ADR 004 method (fresh throwaway-server `list-keys` diff). The diff
  is **not empty**, but every changed line is benign and was expected:
  - `copy-mode-vi !` and `copy-mode !` (copy-without-newline helper) flip from
    `copy-pipe-and-cancel` to `copy-pipe` — `@yank_action` is global. `!` is an
    internal helper for tmux-yank's copy-line feature, not pressed directly.
  - `copy-mode y` (emacs table) flips likewise — the emacs table never fires under
    `mode-keys vi`.
- Adds a small dependency on tmux-yank internals for the yank keys; documented here and
  in the config comments so a future reader isn't surprised.

## Useful Commands

Inspect what tmux-yank actually binds (source of truth for this decision):

```bash
grep -nE "bind-key|yank_action|put_default|pbcopy" \
  ~/.config/tmux/plugins/tmux-yank/yank.tmux \
  ~/.config/tmux/plugins/tmux-yank/scripts/helpers.sh
```

Confirm the effective copy keys on a fresh server:

```bash
tmux -L vtest -f ~/.config/tmux/tmux.conf new-session -d
tmux -L vtest list-keys | grep -E "copy-mode(-vi)? +(y|Y|MouseDragEnd1Pane) "
tmux -L vtest kill-server
```
