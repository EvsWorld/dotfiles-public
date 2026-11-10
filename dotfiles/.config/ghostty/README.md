# Ghostty Configuration

Ghostty is the terminal at the base of the keybinding stack: Karabiner -> Ghostty -> tmux -> Neovim.

## Files

| Path | Purpose |
| --- | --- |
| `config` | The only file Ghostty reads. There is no `config-file` directive, so nothing else is loaded. |
| `docs/001-alt-key-keybinding-changes.md` | How Ghostty translates key events into bytes, and what the alt-key bindings do. |
| `exampleConfigs/` | Reference copies of other people's Ghostty configs. Not loaded, kept for ideas. |
| `themes/` | Empty. Themes come from Ghostty's built-ins via the `theme` setting. |

Note that Ghostty's config format is plain `key = value`, **not** TOML.
A `config.toml` file in this directory would never be read, and one existed here by mistake until 2026-09-04.

## Pane management belongs to tmux

Ghostty's own splits, tabs, and split-resize bindings are **deliberately unused**.
tmux owns all pane and window management, so the same keys work identically over SSH, inside a nested session, and after a reattach.

This is why `config` contains almost no `new_split`, `goto_split`, `resize_split`, or `new_tab` bindings, even though Ghostty supports all of them.
Earlier experiments with those bindings were removed on 2026-09-04; see git history for `ghosttyExperiments.toml` if you want them back.

The one exception is `super+shift+h/j/k/l` -> `goto_split`, kept for the rare case of a Ghostty-level split.

## Keyboard encoding

The important and non-obvious behavior is documented separately, because it is easy to get wrong and expensive to rediscover:

- **`docs/001-alt-key-keybinding-changes.md`** - the key-event to byte translation, what `macos-option-as-alt` changes, the default encoder table, and the difference between `text:`, `ignore`, and `unbind`.
- **`~/.config/docs/adrs/021-pane-resize-on-ctrl-option-hjkl.md`** - why pane resize sits on `ctrl+option+hjkl`, and the two interceptors that hid it.
- **`~/.config/docs/adrs/014-tmux-prefix-via-karabiner-app-scoped-remap.md`** - why Command has no terminal encoding, and how Karabiner works around global hotkeys.

The short version: Ghostty is the only component that converts key events into bytes, the conversion is lossy and one-way, and nothing downstream of it ever sees a modifier.

## Reloading

`Cmd+R` reloads the config in place (`keybind = super+r=reload_config`).

To check what Ghostty actually parsed:

```bash
/Applications/Ghostty.app/Contents/MacOS/ghostty +list-keybinds
```

## Open items

Tracked in `~/.config/docs/TODO.md` under "Ghostty".
