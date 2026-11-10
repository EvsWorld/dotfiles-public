# ADR 017: Retire SessionX in Favor of sesh, and Give `f` to the Agent Sidebar

## Status

Accepted (2026-08-19)

Supersedes [ADR 009](009-sessionx-fast-custom-paths.md),
[ADR 012](012-sessionx-session-recency-fork.md), and
[ADR 013](013-sessionx-secondary-launch-binding.md).

## Context

SessionX was the session picker, launched from `Prefix+f` via `@sessionx-bind`
and from a secondary `Prefix+n` binding in `bindings.conf` (ADR 013). In
practice `sesh` replaced it: `bindings.conf` was pointed at
`scripts/sesh.sh` and the SessionX launcher was commented out, leaving the
plugin loaded, its dozen `@sessionx-*` options in `tmux.conf`, and a fork of
the upstream repository (ADR 012) maintained for a picker nobody opened.

Separately, `hiroppy/tmux-agent-sidebar` was still on its default keys, `e` to
toggle the sidebar in the current window and `E` to toggle it everywhere. Those
keys were never chosen; they became load-bearing when
`@sidebar_auto_create off` made sidebars opt-in, so the toggle is now pressed by
hand many times a day and deserves a key close to the home row. The best
candidate, `f`, was held by a plugin that was already dead in practice.

## Decision

Remove SessionX entirely: the `@plugin` declaration, every `@sessionx-*`
option, and the dead commented-out bindings. `sesh` on `Prefix+n` is the only
session picker.

Bind the agent sidebar in `bindings.conf`, which is sourced after TPM:

```tmux
unbind e
unbind E
bind -N "Agent sidebar: toggle in this window" f \
  run-shell '…/tmux-agent-sidebar/bin/tmux-agent-sidebar toggle "#{window_id}" "#{pane_current_path}"'
bind -N "Agent sidebar: toggle in all windows" F \
  run-shell '…/tmux-agent-sidebar/bin/tmux-agent-sidebar toggle-all'
```

`Prefix+F` displaces tmux-fzf's launcher, which is accepted: `Prefix+?`
(`scripts/keys.sh find`) already searches every binding with better
descriptions.

## Rationale / Alternatives Considered

- **Set `@sidebar_key` / `@sidebar_key_all` in `tmux.conf` instead.** One line
  shorter, but it puts keys outside `bindings.conf` (ADR 004), leaves the
  outcome dependent on TPM plugin ordering, and produces bindings with no `-N`
  note, so `Prefix+?` would show a raw binary path.
- **Keep SessionX installed and just move `@sessionx-bind` off `f`.** Rejected:
  it preserves a fork, a plugin, and fourteen options for a picker that has been
  replaced. Reducing redundancy is the point.
- **Keep tmux-fzf on `Prefix+F` and put the sidebar elsewhere.** Rejected: the
  sidebar is used daily and tmux-fzf's key list is not, and no other free key is
  as close to `f`.
- **Delete ADRs 009, 012, and 013.** Rejected: they are the record of why the
  fork and the custom-path tradeoff existed. They are marked superseded instead.

## Files Touched

- `tmux.conf` - SessionX plugin line and option block removed; sidebar comment
  now names `f` / `F`.
- `bindings.conf` - sidebar section added, dead SessionX lines removed, the
  `sesh` binding note simplified.
- `README.md` - SessionX section replaced with an Agent Sidebar section;
  keybinding lists, plugin lists, and resources updated.
- `docs/adr/009`, `012`, `013` - marked superseded.

## Consequences

The installed `plugins/tmux-sessionx` checkout, including the recency fork, is
no longer loaded and can be removed with TPM's `Prefix+Alt+u`. Recovering
SessionX means restoring the plugin line and its options from git history.

Because the binding lives in `bindings.conf` with the plugin's binary path
written out, a change to the plugin's install layout requires updating that
path - the same tradeoff `Prefix+i` (Floax) already makes.

`@sessionx-*` options already set in a running tmux server persist until the
server restarts; removing the `set` lines only stops them being re-applied.
