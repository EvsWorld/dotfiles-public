# ADR 018: Enable `automatic-rename` to Get Nerd Font Window Icons

## Status

Superseded (2026-08-21) by
[ADR 019](019-remove-nerd-font-window-name-active-pane-only.md).

`automatic-rename` labels a window from its active pane only, so with several
panes per window the icon tracked whichever pane was focused last. The plugin
and this decision were reverted.

## Context

The status bar labelled windows with whatever the shell reported, so a session
of eight windows read `zsh`, `zsh`, `node`, `zsh`, `nvim`, `node`. That is
almost no signal at a glance, and finding the right window meant reading every
label instead of recognizing a shape.

`joshmedeski/tmux-nerd-font-window-name` solves this by rendering a Nerd Font
glyph per window, keyed on the process actually running there. Its entire
mechanism, though, is one line:

```bash
tmux set-option -g automatic-rename-format "$new_format"
```

tmux consults `automatic-rename-format` only for windows whose
`automatic-rename` is `on`. This config had:

```tmux
set -g automatic-rename off   # stop the rename whenever you cd
```

so the plugin would have installed cleanly, loaded without error, and done
nothing at all. That `off` was a deliberate fix for a real annoyance: with the
stock format, every `cd` renamed the window to the new directory.

## Decision

Set `automatic-rename on` in `tmux.conf`, and install the plugin with a user
icon config at `tmux-nerd-font-window-name.yml`.

Leave `allow-rename off` untouched. It governs renames driven by terminal
escape sequences (OSC 0/2) emitted by the running application, which is a
separate mechanism from `automatic-rename` and is still unwanted.

Do not set `icons-regex` or `names-regex`.

## Rationale / Alternatives Considered

- **The original `cd` annoyance does not come back.** It was a property of the
  *format*, not of `automatic-rename` itself. The plugin replaces the format
  with one derived from `pane_current_command`, so the directory never enters
  the window name.
- **Manual names survive.** `cmd-rename-window` sets a window's own
  `automatic-rename` to `0`, so `Prefix+r` still pins a name permanently and the
  global `on` does not override it. Hand-naming a window remains the escape
  hatch, which is what the old README meant by "manual naming encouraged".
- **Leave `automatic-rename off` and skip the plugin.** Rejected: it preserves
  the status quo, but there is no way to get per-window icons without it. The
  option is not optional here.
- **Set a custom `automatic-rename-format` with `#{window_icon}`** (for example
  `#{window_icon} #{b:pane_current_path}`, icon plus directory basename).
  Rejected for now: the process name is the more useful discriminator when
  several windows sit in the same project directory, which is the normal case in
  a session-per-project workflow. The plugin reads the placeholder out of
  `automatic-rename-format` at load time, so adopting this later means setting
  it *before* `run tpm`.
- **`icons-regex` / `names-regex` for finer matching.** Rejected. These are the
  only settings that make the plugin call `child_cmdlines`, which forks `ps` on
  every refresh. With them unset, a refresh is a single bash job per window.
  Given that `tmux-agent-sidebar` drove load1 to 137 by forking four processes
  per window per second
  ([writeup](../2026_08_19-sidebar-fork-storm-load-spike.md)), the cheap path is
  worth keeping by default. `status-interval` is `5` (set by tmux-sensible), so
  the cost is one bash fork per window per five seconds.

## Files Touched

- `tmux.conf` - `automatic-rename` flipped to `on` with the reasoning inline;
  `@plugin` line and `@tmux-nerd-font-window-name-config-file` added.
- `tmux-nerd-font-window-name.yml` - new; icon overrides.
- `README.md` - plugin listed, and the stale "automatic window renaming
  disabled" behavior note corrected.

## Consequences

Upstream `bin/defaults.yml` ships no icon for `claude`, `codex`, or `gemini`,
the CLIs used most here, so all three would render as the `?` fallback. The
user config adds them; new tooling needs an entry there or it falls back too.

Because the plugin resolves icons from `pane_current_command`, a CLI can report
something other than its own binary name. Claude Code does exactly this: it
reports its version, so every Claude window rendered as `? 2.1.220`. That is
handled by `sem-version-icon`, which the plugin already gates behind a
`^[0-9]+\.[0-9]+(\.[0-9]+)?$` match but ships as `null`. Setting it costs
nothing at runtime.

The label therefore reads `2.1.220` rather than `claude`. Rewriting the
displayed *name* is possible only via `names-regex`, which was written,
verified against the real command line, and then deliberately removed.

The reason is cost, and it is worse than "one `ps`": `child_cmdlines` runs
`ps -Ao ppid=,args=`, a full process-table dump, once per window per refresh.
At ~70 windows and `status-interval 5` that is roughly 14 full dumps per
second, permanently, to prettify a label. The icon already identifies the
window, which was the actual goal. Rejected as not worth it.

Windows currently open in a running server keep their existing names until
something triggers a rename; the effect is fully visible after a server restart.
