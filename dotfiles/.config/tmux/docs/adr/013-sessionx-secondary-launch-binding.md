# ADR 013: Add SessionX Launch Keys in the Post-Plugin Bindings Layer

## Status

Superseded by [ADR 017](017-retire-sessionx-for-sesh.md) (2026-08-19).
Originally accepted (2026-07-28).

## Context

SessionX's `@sessionx-bind` option configures one primary prefix key. The
existing configuration uses it for `Prefix+f`. Replacing that value with `n`
would move the launcher rather than add a second shortcut.

The tmux configuration has a deliberate split: plugin options live in
`tmux.conf`, while `bindings.conf` is sourced after TPM and owns user
keybindings.

## Decision

Keep the plugin's primary binding as:

```tmux
set -g @sessionx-bind 'f'
```

Define the additional launcher in `bindings.conf`:

```tmux
bind n run-shell $HOME/.config/tmux/plugins/tmux-sessionx/scripts/sessionx.sh
```

Both `Prefix+f` and `Prefix+n` therefore invoke the same SessionX script.

## Rationale / Alternatives Considered

- **Change `@sessionx-bind` from `f` to `n`.** Rejected because it removes
  `Prefix+f` instead of adding `Prefix+n`.
- **Define both keys through the plugin option.** Not supported by SessionX's
  single-key option.
- **Put the extra binding in `tmux.conf` before TPM.** Rejected because the
  post-plugin `bindings.conf` layer is the canonical home for user bindings
  and guarantees the binding wins over plugin defaults.

## Files Touched

- `tmux.conf` — explains the one-primary-key constraint.
- `bindings.conf` — defines the additional `Prefix+n` launcher.
- `README.md` — documents both SessionX shortcuts and the reason for the
  split.

## Consequences

The two shortcuts remain equivalent while the plugin's supported configuration
stays intact. If the installed SessionX script moves, the direct secondary
binding must be updated with it; `Prefix+f` continues to follow the plugin's
own binding behavior.
