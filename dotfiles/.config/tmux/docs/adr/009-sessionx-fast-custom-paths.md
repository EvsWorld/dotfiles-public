# ADR 009: Keep SessionX Custom-Path Expansion Disabled

## Status

Superseded by [ADR 017](017-retire-sessionx-for-sesh.md) (2026-08-19).
Originally accepted (2026-07-13).

## Context

Opening SessionX with `Prefix+f` had become extremely slow. The binding itself
only launches the plugin; the expensive work came from combining six custom
path roots with `@sessionx-custom-paths-subdirectories 'true'`.

With subdirectory expansion enabled, the installed SessionX script discovered
about 73 immediate child directories. Its current `handle_input` implementation
also invokes `additional_input` twice, and each invocation filters the paths by
starting one Bash process per discovered directory with `xargs -P 0`. That made
one popup launch perform roughly twice the configured directory-discovery work.

The duplicate call is also present upstream. Editing the TPM-managed plugin
checkout locally would be fragile because a plugin update or reinstall could
overwrite the patch and leave this configuration silently diverged from
upstream.

## Decision

Keep custom-path subdirectory expansion disabled:

```tmux
set -g @sessionx-custom-paths-subdirectories 'false'
```

Keep zoxide integration enabled. The resulting workflow is:

- `Prefix+f` opens the fast list of tmux sessions and explicitly configured
  custom roots.
- `Ctrl+y` inside SessionX reloads the picker with `zoxide query -l` so known
  directories remain available without eager expansion on every launch.
- Selecting a directory creates a tmux session rooted there when one does not
  already exist; despite the plugin option name `bind-zo-new-window`, this is
  not tmux pane zooming.

Do not patch `plugins/tmux-sessionx/scripts/sessionx.sh` locally. If the
upstream duplicate computation needs fixing, prefer an upstream issue or pull
request.

## Rationale / Alternatives Considered

- **Keep subdirectory expansion enabled.** Rejected because disabling it made
  the popup noticeably faster in live testing.
- **Patch the installed plugin.** Rejected because TPM owns that checkout and
  can replace local edits during updates.
- **Remove custom paths entirely.** Not chosen yet; keeping the explicit roots
  preserves a small predictable set of launch targets.
- **Disable previews.** Not needed after the first isolated change improved
  launch time. It remains a useful second diagnostic if startup regresses.

## Files Touched

- `tmux.conf` — disables SessionX custom-path subdirectory expansion.
- `README.md` — documents the fast default list and the actual `Ctrl+y`
  zoxide workflow.
- `docs/adr/009-sessionx-fast-custom-paths.md` — records the diagnosis,
  decision, and tradeoffs.

## Verification

```bash
tmux source-file $HOME/.config/tmux/tmux.conf
tmux show-option -gqv @sessionx-custom-paths-subdirectories
tmux list-keys -T prefix | grep sessionx.sh
```

The option should print `false`, and `Prefix+f` should continue to launch
SessionX. Open it several times and confirm that it appears quickly; use
`Ctrl+y` inside the picker when a zoxide directory is needed.
