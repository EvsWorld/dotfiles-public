# ADR 007: Route `Ctrl+u`/`Ctrl+d` by Alternate Screen; Keep Claude Code on the Classic Renderer

## Status

Accepted (2026-07-02)

## Context

`Ctrl+u`/`Ctrl+d` are the universal half-page scroll keys (see the root-table
bindings in `bindings.conf`). The old implementation special-cased apps by
process name: pass through for vim and the aoe popup/dashboard, `ps | grep
opencode` → send PageUp/PageDown, everything else → `copy-mode` +
`halfpage-up/down`.

This silently broke for Claude Code around v2.1.89: Claude Code gained a
**fullscreen renderer on the terminal's alternate screen buffer** (enabled here
via `"tui": "fullscreen"` in `~/.claude/settings.json`, likely accepted from an
in-app prompt). On the alternate screen a pane has no tmux scrollback above the
visible grid, so the fallback branch entered copy mode but `halfpage-up` had
nothing to scroll. Symptom: "enters copy mode but does NOT page up."

Two additional facts shaped the fix:

- Any app that runs on the alternate screen necessarily owns its scrollback
  (opencode, Claude Code in fullscreen mode, vim). Fullscreen Claude Code
  scrolls natively with PageUp/PageDown.
- Codex CLI renders inline on the primary screen and its chat view has **no
  scroll keys at all** (openai/codex#23280 still open); tmux copy mode is
  genuinely the best scroll mechanism for it.

## Decision

Two coordinated changes:

1. **tmux (`bindings.conf`): branch on `#{alternate_on}` instead of process
   names.** After the aoe and `is_vim` passthrough checks, if the pane is on
   the alternate screen send `PageUp`/`PageDown` (the app owns its scrollback);
   otherwise enter copy mode and half-page tmux history. The aoe check became a
   pure tmux format (`if-shell -F`), and the `ps | grep opencode` branch was
   deleted — `#{alternate_on}` covers opencode and any future alt-screen TUI.

2. **Claude Code: `"tui": "default"` in `~/.claude/settings.json`.** The
   classic inline renderer keeps the transcript in tmux's native scrollback, so
   Claude Code panes take the copy-mode branch like shells and codex. The
   desired behavior everywhere is "page up **and** land in copy mode", and only
   primary-screen apps can provide it.

## Rationale / Alternatives Considered

- **Add a claude-specific `ps` grep (like opencode had).** Rejected: grows the
  process-name whitelist forever; `#{alternate_on}` is the actual property that
  matters and needs no per-app maintenance. It also matches the idiom the
  `root WheelUpPane` override already uses (see
  [ADR 006](006-mouse-scroll-no-exit-copy-mode.md)).
- **Keep Claude Code fullscreen and rely on PageUp passthrough.** Worked, but
  scrolling happened inside Claude's own buffer — no copy mode, inconsistent
  with every other pane. Rejected for consistency.
- **Codex `tui.alternate_screen = "always"` for symmetry.** Rejected: codex's
  chat view ignores scroll keys, so `Ctrl+u` would do nothing there.

Tradeoff of the classic Claude renderer: some redraw flicker during fast
streaming output, no in-app mouse interactions, and the input UI scrolls with
the transcript. `/tui fullscreen` flips back at any time; the tmux binding
adapts automatically in either mode because it keys off `#{alternate_on}`.

## Files Touched

- `bindings.conf` — rewrote the root `C-u`/`C-d` bindings (aoe check as a
  format, `#{alternate_on}` branch, removed the opencode `ps` grep and stale
  TODO); comment documents the Claude Code renderer choice.
- `~/.claude/settings.json` — `"tui": "fullscreen"` → `"tui": "default"`.
- `README.md` — Scrolling section updated to describe the routing.

## Consequences

- `Ctrl+u`/`Ctrl+d` behave identically in shells, codex, and Claude Code:
  half-page scroll that lands in copy mode.
- opencode is the one holdout (alternate-screen only, no inline mode): it still
  receives PageUp/PageDown and scrolls its own view.
- Running Claude Code sessions started before the settings change stay
  fullscreen until restarted or switched with `/tui default`.
- Any future alternate-screen TUI gets sensible behavior (PageUp/PageDown) with
  zero config changes.

## Useful Commands

```bash
tmux display -p -t <pane> '#{alternate_on} #{pane_current_command}'  # which branch a pane takes
tmux list-keys -T root | grep -E 'C-[ud]'                            # verify bindings loaded
```
