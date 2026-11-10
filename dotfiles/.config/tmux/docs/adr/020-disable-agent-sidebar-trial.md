# ADR 020: Disable the Agent Sidebar for a Trial Period

## Status

Proposed trial (2026-11-04), to be decided by about 2026-11-08.
Reaches Accepted (removed or replaced) or Reverted (re-enabled) at the end of the trial.

Does not supersede [ADR 017](017-retire-sessionx-for-sesh.md), which gave `f` to the sidebar.
If the trial ends in removal, `f` is free again and ADR 017's key assignment is moot.

## Context

tmux has been lagging.
`hiroppy/tmux-agent-sidebar` is the one plugin with a documented history of causing exactly that.
See [the fork-storm writeup](../2026_08_19-sidebar-fork-storm-load-spike.md) and [Laggy Redraws](../TROUBLESHOOTING.md#laggy-redraws).

Two mitigations were already in place and the lag persisted or returned:

- `@sidebar_auto_create off`, so sidebars exist only when opened by hand.
- `unlag` / `sidebar-prune`, which closes every sidebar pane.

The plugin is more than the pane.
It also installs agent hooks, so the sidebar's footprint is wider than the pane suggests:

| Piece | Where | Runs when |
|---|---|---|
| Sidebar pane (Rust daemon, polls each second) | `tmux.conf` plugin line, `bindings.conf` `f` | a sidebar is open |
| Claude Code plugin hooks | `~/.claude/settings.json` (`tmux-agent-sidebar@hiroppy`) | every Claude session start, prompt, notification, tool event |
| Codex hooks | `~/.codex/hooks.json` (`hook.sh codex ...`) | every Codex session start, prompt, tool call, stop |

The hooks run `hook.sh` whether or not any sidebar is open.
Disabling only the pane would leave that background activity in place and make the experiment inconclusive.

## Decision

Disable all three pieces and work without the sidebar for a few days, then decide.

- `tmux.conf`: comment out the `@plugin 'hiroppy/tmux-agent-sidebar'` line and `@sidebar_auto_create`.
- `bindings.conf`: comment out `unbind e`, `unbind E`, and the `bind f` toggle.
- `~/.codex/hooks.json`: remove the four `tmux-agent-sidebar/hook.sh codex ...` entries.
  The `llm-hook-*` entries in the same file are unrelated and stay.
- `~/.claude/settings.json`: set `tmux-agent-sidebar@hiroppy` to `false`.

Everything is commented out or flipped, never deleted.
The plugin directory stays on disk, so re-enabling is the reverse of each edit plus a reload.

## Why

- **Isolates the variable.** Removing one suspect completely is a binary chop: if the lag disappears, the cause is found; if not, the sidebar is ruled out and the search moves on.
- **Partial disables are not a fair test.** Auto-create was already off and the pane alone was not obviously the source, so the hooks have to go too.
- **Reversible.** A few days of real use is a better signal than a synthetic benchmark, and nothing is lost if the answer is "put it back".
- **Cost of the trial is low.** The sidebar is convenient (a live list of AI conversations with jump-to-pane), not load-bearing.

## Rejected alternatives

- **Keep the sidebar, tune it harder:** two rounds of mitigation already; the underlying polling has no backoff upstream.
- **Disable only the pane (`f` binding and plugin line):** leaves the hooks running and muddies the result.
- **Uninstall the plugin now:** premature. The sidebar is genuinely useful, and the point of the trial is to find out whether it is worth its cost before deleting it.

## How to decide

After a few days without it:

- **Lag gone:** remove the plugin for good, or look for a replacement (a lighter status view, or a fix for upstream polling backoff).
  Record the outcome by updating this ADR's status and, if `f` is reassigned, amending ADR 017.
- **Lag unchanged:** re-enable, and the search continues elsewhere (see [Finding a new cause](../TROUBLESHOOTING.md#finding-a-new-cause)).

## Re-enabling

1. Uncomment the plugin line and `@sidebar_auto_create off` in `tmux.conf`.
2. Uncomment the sidebar block in `bindings.conf`.
3. Set `tmux-agent-sidebar@hiroppy` back to `true` in `~/.claude/settings.json`.
4. Restore the Codex hooks from `~/.codex/hooks.json.bak-sidebar`.
5. Reload with `tmux source-file ~/.config/tmux/tmux.conf`, then restart agent sessions so they pick up the hooks.
