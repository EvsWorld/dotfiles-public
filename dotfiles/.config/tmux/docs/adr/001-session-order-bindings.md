# ADR 001: Session Order Navigation Bindings

## Status

Accepted

## Context

Tmux sessions are used as project-level workspaces. Fast session switching should therefore feel like moving between major project contexts, not like moving between windows inside the current project.

The existing config already has these related bindings:

- `Prefix+l` switches to the last session with `switch-client -l`.
- `Prefix+C-n` and `Prefix+C-p` are live bindings for next and previous window.
- `Prefix+f` opens SessionX for fuzzy session selection.

Reusing `Prefix+C-n` and `Prefix+C-p` for sessions would match next/previous naming, but it would remove window cycling bindings. Bracket bindings are also plausible, but `[` and `]` have been considered for prompt navigation.

## Decision

Use Vim jump-list logic for ordered session cycling:

- `Prefix+C-o`: previous session by order using `switch-client -p`.
- `Prefix+C-i`: next session by order using `switch-client -n`.

This mirrors Vim's jump-list behavior where `C-o` moves backward and `C-i` moves forward.

## Consequences

- Ordered session cycling has direct keyboard bindings.
- Existing window cycling bindings remain available.
- Session navigation now has three complementary paths: last session, ordered cycling, and fuzzy selection.
- The binding depends on the user remembering the Vim jump-list metaphor rather than the literal `n`/`p` next/previous mnemonic.
