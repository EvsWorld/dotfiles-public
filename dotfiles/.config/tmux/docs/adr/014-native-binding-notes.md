# ADR 014: Describe Bindings with `bind -N`, Generate Hints From Them

## Status

Accepted (2026-07-30)

## Context

Neovim has `folke/which-key.nvim` (`~/.config/nvim/lua/kickstart/plugins/which-key.lua`):
press part of a chord, and after `delay = 800` a popup lists the valid
continuations with descriptions. There was no equivalent on the tmux side.

Three discovery affordances already existed here and none read like which-key:

| Binding | Problem |
|---|---|
| `Prefix+?` → `list-keys` | raw `bind-key` syntax, 66 prefix lines, no descriptions |
| `Prefix+F` → tmux-fzf `keybinding.sh` | fuzzy-lists *and* executes, but over the same raw syntax |
| `Prefix+C` → `customize-mode -Z` | an options browser, not a key list |

The root cause was not a missing tool. tmux has had a native description field
since 3.1 — `bind-key -N "note"`, read back with `list-keys -N` — and this
config had **zero** notes. `unbind-key -a` (`tmux.conf`) strips tmux's shipped
bindings *and the notes attached to them*, and every description in
`bindings.conf` lived in a `#` comment, which tmux cannot see. The descriptions
were already written; they were just in a form only humans could read.

which-key works the same way underneath: it reads `desc` off the keymap itself,
which is why its `spec` block only has to name *groups*, not every binding.

## Decision

Move descriptions onto the bindings as `-N` notes, and generate both hint
front-ends from them. `bindings.conf` remains the single source of truth
(ADR 004); nothing is hand-restated.

```tmux
bind -N "Zoom pane (toggle fullscreen)" -T window-ops e resize-pane -Z
```

Two front-ends, one script (`scripts/keys.sh`):

| Binding | Front-end | Shape |
|---|---|---|
| `Prefix+w` | `keys.sh menu window-ops` | generated `display-menu` — press the real key |
| `Prefix+w`, `m` | `keys.sh menu window-ops-move` | nested menu, listing the target windows |
| `Prefix+w`, `r` | `keys.sh menu window-ops-reorder` | nested menu, listing the target positions |
| `Prefix+?` | `keys.sh find` | fzf popup across six tables — search a description |

Menus nest: a menu item may open another menu, which is how the digit tables
keep their hints instead of dropping into a silent key table mid-chord.

**Neither front-end reconstructs a command.** Both resolve `<table> <key>` and
delegate to `keys.sh exec`, which looks the command up from tmux at execution
time and re-runs it via `tmux run-shell -C`.

`-C` is load-bearing: it makes **tmux** parse the string rather than a shell.
`list-keys` output is escaped for tmux's own parser, and the two disagree. A
leading `~` is emitted as `\~`; bash's double-quote rules preserve that
backslash, so an `eval "tmux $cmd"` implementation handed `/bin/sh` a literal
`\~/…` path and every tilde-bearing binding died with **exit 127**. Since the
string comes from tmux, tmux should parse it.

One wrinkle: `-C` reads `\;` as a literal argument rather than a command
separator, which would break multi-command binds like
`swap-pane -s '{left-of}' \; display-message "…"`. `exec` therefore rewrites
`\;` to plain `;` before handing the string over — verified that `-C` treats
plain `;` as a separator.

Bindings with no note yet fall back to their command text as the description.
Without that, the 66-binding prefix table renders as rows of blank descriptions —
useless exactly where the list is longest.

Single-digit keys are reordered so `0` sorts after `9`, and the harpoon keys
`j k l : '` after them in that order. `list-keys` sorts by ASCII, which puts `0`
first and `:` before `j`, but throughout this config `0` means *ten* and
`j k l :` mean windows 1-4 — a menu listing "10, 1, 2, …" reads as a bug.

This is applied **per table**, only where those keys carry that meaning
(`prefix`, `window-ops-move`, `window-ops-reorder`). In `copy-mode-vi` the same
keys are cursor movement, goto-line, and repeat counts, and in `window-ops`
`j`/`k`/`l` are pane swaps — both keep tmux's ordering. Only rows in a reordered
group move; they stay in the slots tmux gave them.

## Rationale / Alternatives Considered

- **`alexwforsythe/tmux-which-key`.** Rejected on two counts. Its default
  triggers are `C-Space` (root) and `prefix + Space`; `C-Space` *is* the prefix
  here and `prefix + Space` is `copy-mode`, so both collide. More importantly it
  is configured by a separate YAML restating every binding — a second source of
  truth, against ADR 004. Generating menus from `-N` is strictly better on that
  axis: the plugin hand-lists what we derive.
- **Hand-written `display-menu` in `bindings.conf`.** Rejected: duplicates all 18
  bindings next to the bindings they mirror, and hits the re-quoting problem above.
- **`display-menu` for everything, including `Prefix+?`.** Rejected: menus
  silently fail past terminal height, and the prefix table has 66 entries.
- **fzf palette only (no menu).** Considered and rejected after review. A palette
  is search-and-run — closer to `:Telescope keymaps` than to which-key, which is
  chord-continuation. Both were kept because they answer different questions:
  "what can I do from here?" versus "where is that binding?"
- **`display-popup -E` instead of `fzf --tmux`.** Rejected: `-E` sends output to
  the popup rather than back to the caller. `fzf --tmux` returns the selection on
  stdout, and is already the pattern at `@fzf-url-fzf-options` in `tmux.conf`.

## Non-obvious `list-keys` behavior

Five findings. (1) and (2) were established on a throwaway server (`tmux -L`, per
ADR 004); (3), (4), and (5) surfaced against the live server — (5) only after the
first version shipped and failed in use:

1. **Notes are invisible to the default form.** A binding carrying
   `-N "Zoom pane"` still prints as plain `bind-key -T window-ops e resize-pane -Z`.
   So adding notes produces a **zero-line** `list-keys` diff, and notes can only
   be verified with `-N`. This is what makes the ADR 004 behavior-preservation
   check sharp here: the expected diff was exactly two lines.
2. **Always pass `-T`.** A bare `list-keys -N` covers only `root` and `prefix`,
   and prepends the prefix string (`C-Space r  Reload config`). Custom tables are
   invisible without an explicit `-T`.
3. **The two forms escape keys differently.** The default form prints `\"`, `\'`,
   `\;`, `\$`; the `-N` form prints them bare. Joining the forms on the key string
   therefore drops those rows *silently* — the worst failure mode for a
   "show me everything" list. `keys.sh` strips a leading backslash before joining.
4. **`NR == FNR` is unsafe for this join.** With the notes stream empty — the
   starting state of every unannotated table — `NR` and `FNR` stay equal across
   the whole second stream, so every command row is eaten as a note and the list
   comes out empty. `keys.sh` tags the two streams instead.

5. **`list-keys` output is tmux-escaped, not shell-escaped.** Re-running it
   through a shell looks like it works — most bindings have nothing to escape —
   and then fails only on the ones that do. `~` is the trap here: emitted as
   `\~`, preserved verbatim by bash double quotes, and 127 at the far end. Feed
   the string back to tmux (`run-shell -C`), never to `eval` or `xargs tmux`.

Also: parse by locating the `-T` token, not a fixed field offset. A leading `-r`
shifts everything (`bind-key -r -T root M-H …`), which is why tmux-fzf's
`$1=$2=$3=$4=""` approach would not work against this config.

## Known Limitation

**There is no equivalent of which-key's `delay = 800`.** tmux has no
hesitate-detect primitive, so hints are either shown immediately on chord entry
or on demand — never "only if you pause." The `Prefix+w` menu therefore appears
instantly. Chords still execute at full speed, because the menu consumes the
keystroke, but there is a visual flash where Neovim shows nothing.

If that proves annoying, reverting one line in `bindings.conf` restores the
silent key table; the notes and `Prefix+?` keep working unchanged:

```tmux
bind w switch-client -T window-ops
```

`keys.sh menu` skips keys containing `'` or `"` rather than emit a broken menu
item, since the key is embedded in a string that tmux parses and then hands to a
shell. Custom op tables are single letters; the prefix table's `'` and `"` are
reachable through `Prefix+?`, which passes keys via argv with no re-parsing.

## Scope

Annotated: every table reachable from `Prefix+w` (`window-ops` 18,
`window-ops-move` 14, `window-ops-reorder` 10), plus 51 of 66 in `prefix` and
the 15 `copy-mode-vi` bindings this config defines.

**The 15 undescribed `prefix` bindings are plugin-created** — SessionX (`f`),
Floax (`i`, `P`), TPM (`I`, `U`, `M-u`), resurrect (`C-r`, `C-s`), yank (`y`,
`Y`), fzf-url (`o`), tmux-fzf (`F`), vim-tmux-navigator (`C-l`), tmux-sensible
(`C-n`, `C-p`). They are not in `bindings.conf`, and `-N` can only be set when a
key is bound, so describing them would mean re-binding each with its plugin's
script path hardcoded. ADR 013 accepted exactly that cost for a single binding
(`n`) and recorded the fragility; paying it fifteen more times to improve a
label would trade this ADR's own single-source-of-truth rule for cosmetics.
They list via the command-text fallback, which names the script.

`root` contributes 13 keyboard bindings, 12 of them described (`C-\` is
vim-tmux-navigator's). `copy-mode-vi` carries 98 bindings — the 15 defined here
plus tmux's built-ins, which survive `unbind-key -a`. The built-ins fall back to
command text (`send-keys -X cursor-down` and friends), which reads well enough.

**Mouse events are excluded from `Prefix+?`.** `root` and `copy-mode-vi` carry
roughly 17 and 7 of them. They cannot be invoked from a keyboard-shortcut list,
and their built-in definitions are long `if-shell` blobs that swamp real
entries. The filter is deliberately unanchored so `M-MouseDown3Pane` is caught
alongside `MouseDown3Pane`. For the same reason, fallback command text is capped
at 76 characters — several `root` bindings inline the entire vim-detection
`ps | grep` pipeline.

## Files Touched

- `bindings.conf` — `-N` notes on all 38 window-op bindings; `Prefix+w`,
  `Prefix+?`, and the `m` / `r` sub-chords repointed at `keys.sh`.
- `scripts/keys.sh` — new; `menu` / `find` / `exec` subcommands.
- `README.md` — documents the menu and the palette.
- `docs/TODO.md` — removed a dead pointer to a deleted fuzzy-key-finder plan.

## Consequences

Adding a binding to `window-ops` with a `-N` note makes it appear in both the
menu and the palette with no further work. Omitting the note still lists it,
showing its command text — visible, and a prompt to describe it.

The three window-op key tables are no longer *entered* via `switch-client`; the
menus execute their bindings by lookup instead. The tables remain the declarative
source of truth, and `switch-client -T <table>` still works if bound elsewhere.
