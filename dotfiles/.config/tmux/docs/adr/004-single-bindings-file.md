# ADR 004: All Keybindings in a Single `bindings.conf` Loaded Last

## Status

Accepted

## Context

Keybindings used to live in two places, split by load order:

- `tmux.reset.conf` was sourced near the top of `tmux.conf`, **before** TPM. It
  started with `unbind-key -a` and defined the "base" bindings.
- A second block of bindings lived at the bottom of `tmux.conf`, **after** TPM
  (copy-mode-vi yank, root `Ctrl+hjkl` no-wrap, `Ctrl+d`/`Ctrl+u` scroll), because
  those had to override plugin defaults.

So the answer to "where does a new binding go?" depended on whether it needed to beat
a plugin, and precedence required reading the whole file top-to-bottom. The `reset`
filename described a job — wiping the keymap — that only made sense pre-plugin.

## Decision

Consolidate every keybinding into one file, `bindings.conf`, sourced as the **last**
line of `tmux.conf` (after `run tpm`). Rename is not the point — the file's role
changed:

- The `unbind-key -a` "reset" moved out of it and into `tmux.conf`, immediately before
  `run tpm`. It must stay pre-TPM; run after TPM it would wipe plugin-created bindings
  (sessionx `f`, floax `i`, fzf-url `o`, resurrect, tmux-fzf).
- With the reset removed, the file no longer resets anything — it only holds bindings,
  and it now loads *last* instead of *first*. `bindings.conf` names what it does;
  `tmux.reset.conf` would have described a behavior it no longer has.

The resulting load order in `tmux.conf` is: base options → plugin declarations +
plugin options → `unbind-key -a` → `run tpm` → post-TPM **visual/theme** overrides
(options, not bindings) → `source bindings.conf`.

**The one rule:** a keybinding always goes in `bindings.conf`, and it always wins
because that file loads last — no load-order reasoning, no "does this beat a plugin?"
question. Visual/theme overrides (`*-style`, `pane-border-*`, `status-right` appends)
stay in `tmux.conf` after TPM because they are options, not bindings; keeping them out
of `bindings.conf` keeps that file purely keybindings.

## Rationale / Alternatives Considered

- **Keep the two-phase split, just rename the files** (e.g. `bindings-pre.conf` +
  `overrides-post.conf`). Rejected: it relabels the confusion instead of removing it —
  you still have to know whether a binding beats a plugin to place it.
- **Move `unbind-key -a` after TPM too, so everything is in one post-TPM file with no
  pre-TPM piece.** Rejected: `unbind-key -a` after TPM wipes plugin bindings that are
  never manually recreated. Keeping only that one line pre-TPM is the price of a clean
  slate, and it is a line you never edit.

Behavior equivalence holds because `bindings.conf` loads after the plugins: the user
always wins, matching today's result whether a plugin guards its binding or binds
unconditionally. The only key that could flip is one bound in the old reset file *and*
bound unconditionally by a plugin *and* not already re-overridden — see Consequences.

## Files Touched

- `bindings.conf` — new; all keybindings (former `tmux.reset.conf` bindings minus
  `unbind-key -a`, plus `bind-key C-Space send-prefix` moved from `tmux.conf`, plus the
  former post-TPM binding block including both file-scoped `is_vim`/`vim_pattern`
  definitions).
- `tmux.conf` — `unbind-key -a` relocated to just before `run tpm`; `bind-key C-Space
  send-prefix` moved out; `source bindings.conf` added as the last line.
- `tmux.reset.conf` — deleted.
- `oh-my-zsh/custom/aliases.zsh` — the `skb` keybinding-search helper now reads
  `bindings.conf` (both `_skb_parse_tmux` and the tmux branch of `_skb_search_and_open`).
- `README.md` — added a "Config File Layout" section documenting the one rule.
- Source-of-truth keybinding-stack lists repointed from `tmux.reset.conf` to
  `bindings.conf` in `~/AGENTS.md`, `tmux/AGENTS.md`, `nvim/AGENTS.md`.

## Consequences

- One obvious home for every keybinding; precedence needs no load-order reasoning.
- `unbind-key -a` is the only binding-related line left in `tmux.conf`, and it must
  stay before `run tpm`.
- Verified behavior-preserving: `list-keys` + `show-options -g`/`-gw` + `show-hooks -g`
  captured from fresh throwaway servers (`tmux -L … -f tmux.conf`) are byte-identical
  before and after. `list-keys` alone is insufficient — it misses `*-style`,
  `pane-border-*`, the assembled `status-right`, and hooks.
- Surfaced a latent bug: `bind ^L refresh-client` had always been shadowed by
  vim-tmux-navigator's `prefix+Ctrl+l → send-keys C-l`. To preserve current behavior it
  is left disabled (commented) in `bindings.conf`; rebind `refresh-client` to a free
  key to actually enable it. See [ADR 002](002-pane-border-visibility.md) for the
  analogous `Prefix+P`/floax precedence case.

## Useful Commands

Prove no behavior change against a throwaway server:

```bash
tmux -L vtest -f ~/.config/tmux/tmux.conf new-session -d
tmux -L vtest list-keys
tmux -L vtest show-options -g
tmux -L vtest show-hooks -g
tmux -L vtest kill-server
```

Find where a binding is defined (all bindings are now in one file):

```bash
grep -n 'copy-pipe' ~/.config/tmux/bindings.conf
```
