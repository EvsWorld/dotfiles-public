# ADR 016: The Floax Left Pane Is the Project Pane

## Status

Accepted

## Context

Floax is used as a split popup: the leftmost pane is transient terminal work that should
follow the directory of whatever pane the popup was opened from, and the panes to its
right hold scratch work whose directory and state must survive across open/close cycles.

The plugin does not support that split. `tmux_popup()` in
`plugins/tmux-floax/scripts/utils.sh` reads the target directory and sends the `cd` with a
**session** target:

```sh
scratch_path=$(tmux display -t "$FLOAX_SESSION_NAME" -p '#{pane_current_path}')
tmux send-keys -R -t "$FLOAX_SESSION_NAME" " cd $current_dir" C-m
```

A session target resolves to that session's **active pane** — whichever pane happened to
have focus when the popup was last closed. Close Floax from the right-hand scratch pane,
`cd` somewhere else in the main session, reopen, and the `cd` lands in the scratch pane,
destroying the context that pane existed to preserve.

A second problem sits behind the first: the `cd` is delivered by `send-keys`, so if the
target pane is running a program rather than sitting at a prompt, the text ` cd <path>` and
a newline are injected into that program. Making the target deterministic makes this worse,
not better — the same pane now absorbs every mistargeted `cd`.

## Decision

Introduce `scripts/floax-left.sh` as a wrapper, bound to `prefix + i` in `bindings.conf`
(which is sourced last and therefore overrides the plugin's own bind). The wrapper:

1. Selects the **project pane** — the leftmost pane of the Floax session's current window
   (smallest `#{pane_left}`, ties broken by smallest `#{pane_top}`) — and leaves focus
   there.
2. Sends the `cd` to that pane only, and only when `#{pane_current_command}` is a shell
   (`zsh`/`bash`/`sh`/`fish`) and its path differs from the origin. Otherwise it shows a
   brief `display-message` and skips.
3. `exec`s the plugin's `floax.sh` to do the actual popup/attach/detach work.

Directory following therefore moves **out of the plugin and into the wrapper**, and
`@floax-change-path` is set to `'false'` in `tmux.conf`. That flag being off does not mean
Floax stopped following directories — it means something else owns it.

Two alternatives were rejected:

- **Patching `utils.sh`.** The plugin is TPM-managed; a local patch is silently reverted by
  the next `prefix + U`, and the failure mode is a behavior regression with no diff to look
  at.
- **Delegating the `cd` and only fixing focus.** Selecting the left pane before calling
  `floax.sh` is enough to aim the `cd` correctly, and was the original design. It cannot
  express "skip the `cd` this time" — `tmux_popup()` offers no hook, only the global
  on/off `@floax-change-path` — so the busy-pane guard forced ownership of the `cd` into
  the wrapper.

Identifying the project pane by **geometry** rather than by pane index or a pinned pane id
keeps the rule stateless: it survives pane swaps, kills, and re-splits, and needs no
second binding to designate a pane.

## Consequences

- Reopening Floax always lands on the project pane and refreshes only that pane's
  directory. Scratch panes are never written to.
- The wrapper never changes windows. If Floax is left on a different window of its session,
  that window's leftmost pane is the project pane for that open.
- Running a long-lived program in the project pane is now safe: focus still moves there,
  the `cd` is skipped, and a message says why.
- `prefix + P` → "pop current window" (`embed.sh pop`) calls `tmux_popup()` directly and no
  longer performs any `cd`, because the plugin's change-path is off. Accepted; that path is
  rarely used.
- Cold start is unchanged: when the session does not exist, `floax.sh` creates it at the
  origin path and the wrapper's pane logic is skipped entirely.
- If the wrapper is ever removed, `@floax-change-path` must go back to `'true'` or Floax
  stops following directories altogether.

## Related

- [ADR 004](004-single-bindings-file.md) — why the override lives in `bindings.conf`
- `scripts/floax-left.sh`, `tmux.conf` (`@floax-*` block), `CONTEXT.md`
  (*Floax project pane*, *Floax scratch pane*, *Directory following*)
