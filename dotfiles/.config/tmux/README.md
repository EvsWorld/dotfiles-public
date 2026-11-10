# Tmux Configuration

## Philosophy
- **Vim-aware navigation**: Seamless switching between vim and tmux panes
- **No prefix navigation**: Core movements (panes, windows, scrolling) work without prefix
- **Window operations menu**: `Prefix+w` opens a which-key style menu for window/pane management
- **Vi-style copy mode**: Familiar vim keybindings for text selection and copying
- **Self-documenting bindings**: descriptions live on the bindings themselves as `bind -N`, so the menu and the key palette are generated, never hand-listed ([ADR 014](docs/adr/014-native-binding-notes.md))

## Key Prefix
- **Prefix**: `Ctrl+Space`, or `left_cmd+Space` (Ghostty only)
- **Reload config**: `Prefix+r`
- **Show all keybindings**: `Prefix+?` (searchable fzf palette; Enter runs the binding)

`left_cmd+Space` is a thumb-friendly second prefix, and it is **not configured in
tmux**. Command has no encoding in the terminal wire protocol, so it cannot be
passed through to tmux at all — Karabiner remaps it to a real `ctrl+space` key
event while Ghostty is frontmost (`ghostty--` block in `~/.config/karabiner.edn`).
tmux only ever sees `C-Space`, so both keys are literally the same key downstream
and tmux's one `prefix2` slot stays unspent.

Consequences: `Ctrl+Space` is the only prefix that works outside Ghostty or with
Karabiner off, so it stays bound. Alfred's main prompt has no key inside Ghostty
(`right_cmd+Space` is a file-finder workflow, not the main prompt); it is
unaffected everywhere else. Provisional — see
[config ADR 014: Second tmux Prefix via a Ghostty-Scoped Karabiner Remap](../docs/adrs/014-tmux-prefix-via-karabiner-app-scoped-remap.md)
(that is the cross-tool `~/.config/docs/adrs/` series, not this directory's
`docs/adr/014`).

---

## Config File Layout

Two files, with one rule so you never have to reason about load order:

| File | Holds | Loaded |
|------|-------|--------|
| `tmux.conf` | base options, plugin declarations + plugin options (`@sidebar_*`, `@floax-*`, `@catppuccin_*`), `unbind-key -a`, `run tpm`, and post-TPM **visual/theme** overrides (`*-style`, `pane-border-*`, `status-right` appends) | entry point (`tmux -f $TMUX_CONF`) |
| `bindings.conf` | **every keybinding** | `source`d as the **last** line of `tmux.conf`, after TPM |

**The one rule:** a keybinding always goes in `bindings.conf`. Because that file is
sourced last (after plugins load), its binds always win over tmux defaults *and*
plugin bindings — no "does this need to beat a plugin?" question.

`unbind-key -a` stays in `tmux.conf` **before** `run tpm` (clean slate before plugins
register their bindings). Do not move it into `bindings.conf`, or it would wipe
plugin-created bindings (floax, agent-sidebar, resurrect, …).

> Note: `prefix + Ctrl+l` is claimed by vim-tmux-navigator (`send-keys C-l`), so the
> historical `refresh-client` binding stays disabled in `bindings.conf` — it never
> took effect. Rebind `refresh-client` to a free key if you want it.

---

## Navigation (No Prefix Required)

### Pane Navigation
- `Ctrl+h/j/k/l` - Move between panes (vim-aware via vim-tmux-navigator)
- Wrapping disabled - won't jump to opposite edge

### Window Cycling
Multiple keybinding options for different preferences:
- **Mnemonic**: `Alt+n` (next) / `Alt+p` (previous)
- **Bracket**: `Alt+]` (next) / `Alt+[` (previous)
- **Directional**: `Alt+l` (next/right) / `Alt+h` (previous/left)

### Scrolling
- `Ctrl+d` - Scroll down (half-page, vim-aware)
- `Ctrl+u` - Scroll up (half-page, vim-aware)

Routing (see [ADR 007](docs/adr/007-route-scroll-keys-by-alternate-screen.md)):
vim and the aoe popup/dashboard get the keys passed through; other
alternate-screen apps (e.g. opencode) get `PageUp`/`PageDown` since they own
their scrollback; everything else (shells, codex, Claude Code with
`"tui": "default"`) enters copy mode and half-pages tmux history.

### Pane Resizing
- `Ctrl+Option+h/j/k/l` - Resize panes (vim-aware)
- `Caps Lock + Option + h/j/k/l` - same thing, in either press order
- Also available: `Prefix+Alt+h/j/k/l` (alternative binding)

Note that `Caps Lock + h/j/k/l` **without** Option is pane *navigation*, not
resizing. `Alt+Shift+h/j/k/l` was the old resize chord and is now explicitly
ignored in `ghostty/config`. See
[ADR 021](../docs/adrs/021-pane-resize-on-ctrl-option-hjkl.md) for how the chord
is encoded and why.

---

## Window Operations Menu (`Prefix+w`)

`Prefix+w` opens a menu listing every window operation with its description.
Press the key to run it, `Esc` to dismiss.
The menu is **generated** from the `-N` notes on bindings in `bindings.conf`, so adding a binding there makes it appear automatically.

**Neovim parity**: The same window operations are available in Neovim under `<leader>w` with identical semantics and aliases (e.g., both `w` and `o` equalize).
See [ADR 027: Align Neovim and tmux Window Operations](../docs/adrs/027-align-neovim-and-tmux-window-operations.md).

Use `Prefix+?` to search all bindings by description.

---

## Sessions & Windows

### Session Management
- `Prefix+n` - sesh fuzzy session picker
- `Ctrl+o` inside sesh - Search direct subdirectories of `~/Projects`; selecting one creates or switches to its session
- `Prefix+h` - Switch to last session
- `Prefix+$` - Rename session
- `Prefix+Ctrl+d` - Detach from session

### Window Management
- `Prefix+c` - New window (inherits current directory)
- `Prefix+R` - Rename window
- `Prefix+1-9` - Jump to window 1-9
- `Prefix+w,r,1-9` - Reorder the current window to position 1-9 (`0` means 10); `r` opens a menu listing the positions
- `Prefix+"` - Interactive window chooser (shows names)

### Pane Management
- `Prefix+Ctrl+c` - Close pane and auto-equalize remaining panes
- `Prefix+z` - Toggle pane zoom
- `Prefix+x` - Swap pane with next

---

## Copy Mode

### Entering Copy Mode
- `Ctrl+/` - Enter copy mode and open backward search (bound as `C-/` and `C-_`; see [ADR 008](docs/adr/008-no-prefix-copy-mode-search.md))
- `Prefix+Space` - Enter copy mode
- `Prefix+Ctrl+u` - Enter copy mode
- Mouse scroll also enters copy mode

### Copy Mode Navigation (Vi-style)
- `v` - Begin visual selection
- `H` - Jump to first non-blank character (like vim `^`)
- `L` - Jump to end of line (like vim `$`)
- `/` - Search backward
- `Ctrl+d` - Half-page down
- `Ctrl+u` - Half-page up
- `Escape` - Exit copy mode
- `Ctrl+c` - Clear selection (stays in copy mode)

### Copying
- `y` - Copy selection without its final trailing newline and exit copy mode
- `Shift+y` - Copy selection without its final trailing newline and stay in copy mode
- `c` - Copy as clean prose and exit: join terminal-wrapped rows, collapse horizontal padding, and preserve blank-line paragraph breaks
- Mouse drag - Copy selection

All copying reaches the macOS clipboard through **`pbcopy` only**. `set-clipboard`
is deliberately `off`, so tmux does not also write the clipboard via the OSC 52
escape sequence — having both writers made some yanks *append* to the clipboard
instead of replacing it (see [ADR 015](docs/adr/015-single-clipboard-writer.md)).

---

## Plugins & Features

### Claude Code and Codex Notifications

Both agent CLIs use the shared `~/scripts/llm-hook-notify.sh` macOS notifier.
Notifications identify the originating work using this title priority:
meaningful LLM session name, tmux session name, then short directory name. The
subtitle includes the tool, directory, and a distinct tmux session when available.

The preview keeps the trailing non-empty response lines within 160 characters,
because conclusions and questions usually appear at the end. Known internal
citation metadata is omitted. Frequently used project roots have distinct macOS
sounds, inherited by their subdirectories; other directories remain silent.

Notifications are suppressed when the originating tmux pane is selected in a
window viewed by a client and Ghostty is the frontmost macOS app. If either
focus check is unavailable or uncertain, the notification is sent normally.
Set `LLM_NOTIFY_DEBUG=1` when invoking the hook manually to print that decision.

See [ADR 011](docs/adr/011-contextual-agent-notifications.md) for the fallback
rules, focus behavior, sound map, and macOS duration limitation.

### Agent Sidebar
- **Currently disabled** as a lag experiment (2026-11-04, decision about 2026-11-08). The plugin line, `f` binding, Claude plugin hooks, and Codex hooks are all switched off, so the bullets below describe the setup when it is enabled. See [ADR 020](docs/adr/020-disable-agent-sidebar-trial.md) for what was turned off and how to re-enable it
- `Prefix+f` - Toggle the agent sidebar in the current window
- `Prefix+F` - Toggle the agent sidebar in every window
- The sidebar shows live Claude Code / Codex agent status per pane and can jump to the pane running an agent
- Sidebars are opt-in: `@sidebar_auto_create off` in `tmux.conf` disables the plugin's per-window auto-create, because each sidebar polls once per second by forking `tmux`/`ps`/`git`/`lsof` with no backoff while its window is hidden
- At 63 windows that auto-create behavior drove load1 to 137; see [the fork-storm writeup](docs/2026_08_19-sidebar-fork-storm-load-spike.md)
- Hand-opened sidebars keep polling after you leave their window, so they still pile up. If tmux redraws lag, run `unlag`, which closes every sidebar and kills stuck lazygit fetches (runbook in [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md#laggy-redraws))
- Both keys are defined in `bindings.conf`, which is sourced after TPM and supersedes the plugin's own `e` / `E`; that also gives them `-N` notes so they show up in `Prefix+?`
- `Prefix+F` displaces tmux-fzf's launcher on purpose - `Prefix+?` already covers keybinding search

### Keybinding Discovery (`Prefix+?`)

- `Prefix+?` - fzf popup over every binding in `root`, `prefix`, `window-ops`,
  `window-ops-move`, `window-ops-reorder`, and `copy-mode-vi`. Search by
  description, `Enter` runs the selected binding, `Esc` cancels.
- Selecting a `copy-mode-vi` binding enters copy mode first, so those are
  runnable rather than reference-only.
- Mouse events (`MouseDown1Pane`, `WheelUpStatus`, …) are excluded — they can't
  be invoked from a keyboard list, and their built-in definitions are long
  `if-shell` blobs. Long fallback text is capped at 76 characters.
- Bindings that carry a `-N` note show that note; the rest fall back to their
  command text, which doubles as a running list of what still needs describing.
- Described: all 42 window-op bindings, 12 of 13 keyboard bindings in `root`,
  and 51 of 66 in `prefix`. The undescribed ones are plugin-created (Floax, TPM,
  resurrect, yank, fzf-url, tmux-fzf, vim-tmux-navigator, tmux-sensible) and
  live outside `bindings.conf`, so they show command text — annotating them
  would mean restating each plugin's own definition.
- Backed by `scripts/keys.sh`, which also powers the `Prefix+w` menu. Both read
  `tmux list-keys -N`, so `bindings.conf` stays the only place keys are defined.

### Floax (Floating Terminal)
- `Prefix+i` - Toggle floating terminal window
- `Prefix+Shift+p` - Floax menu (resize, fullscreen options)
- Session name: `floax-floating-window-session-name`
- Size: 85% width × 85% height

- Split the popup vertically and keep directory-following work in the **left** pane:
  opening Floax focuses the left pane and `cd`s it to the directory you opened from.
  Panes to the right are scratch — they keep their own directory. If the left pane is
  running something instead of sitting at a prompt, the `cd` is skipped.
- Implemented by `scripts/floax-left.sh` ([ADR 016](docs/adr/016-floax-left-pane-is-project-pane.md)).

### Other Plugins
- **vim-tmux-navigator** - Seamless vim/tmux pane navigation
- **tmux-resurrect** - Save/restore tmux sessions, windows, panes, layouts, and directories
- **tmux-continuum** - Auto-save every 15 minutes and auto-restore layouts on tmux server startup
- **tmux-yank** - Copy to system clipboard
- **tmux-fzf-url** - URL picker is fixed and working. From a pane containing URLs, press `Prefix+o`, select a URL, and press `Enter` to open it.
- **catppuccin/tmux** - Official theme. Drives the whole palette from `@catppuccin_flavor`, which follows the system appearance automatically. See [ADR 031](../docs/adrs/031-theme-aware-focus-indication-across-the-stack.md) and [ADR 032](../docs/adrs/032-follow-system-appearance-across-the-stack.md)

---

## Configuration Details

### Behavior
- Windows start at index 1 (not 0)
- Windows auto-renumber when closed
- Automatic window renaming disabled (manual naming encouraged)
- Don't exit tmux when closing last session
- Mouse support enabled
- History limit: 1 million lines
- Restore policy: layouts, directories, saved pane commands, and scrollback all restore automatically on server start. Neovim state is restored by `auto-session`, never by tmux-resurrect. See [ADR 003](docs/adr/003-layout-only-session-restore.md)

### Visual
- Status bar at top (macOS style)
- Terminal title shows session name
- Light/dark follows the system appearance automatically, within about 5 seconds. `Prefix+T` forces a flavor by hand; the override holds until the system appearance next changes. Running Neovim and Claude Code instances keep their startup theme and need a restart. See [ADR 032](../docs/adrs/032-follow-system-appearance-across-the-stack.md)
- Focus is shown by a dimmed inactive pane background plus fuchsia active separators on a magenta-tinted fill, chosen per Catppuccin flavor. Native tmux borders do not form complete boxes at the outer window edges. Pane labels are off so horizontal separators keep the active border color. See [ADR 002](docs/adr/002-pane-border-visibility.md)
- Full-width yellow status bar in copy mode

---

## Tips & Best Practices

### Window Organization
- **Name your windows**: Use `Prefix+R` to rename windows for clarity
- **Use direct selection**: `Prefix+1-9` is faster than cycling once you know window positions
- **Keep it organized**: Logs in window 1, editor in 2, etc. Consistency reduces cognitive load

### When to Use What
- **sesh** (`Prefix+n`): Switching between projects/session
- **Direct window selection** (`Prefix+1-9`): When you know where you're going
- **Window cycling** (`Alt+n/p/etc`): Browsing or finding something
- **Window chooser** (`Prefix+"`): When you forgot window names/numbers

### Pane Management Strategy
- Use `Prefix+w` (then `w` or `o`) frequently to equalize panes after splits; both keys work identically
- `Prefix+w+n` to temporarily hide panes (they persist as background windows)
- `Prefix+Ctrl+c` to close panes (auto-equalizes remaining panes)
- **Muscle memory tip**: The same `<leader>w` operations work in Neovim with identical meaning, so learning one set teaches both tools

### Save Pane Output
From a shell attached to the tmux server, run this to write the last 5,000 lines from pane 0 in the current window to your Desktop:

```bash
tmux capture-pane -p -t :.0 -S -5000 > "$HOME/Desktop/old-mac-audit.txt"
```

At tmux's `:` command prompt, run these as two separate commands to capture pane 0 and save the newest capture buffer:

```tmux
capture-pane -t :.0 -S -5000
save-buffer ~/Desktop/storage-strategy-window-1-pane-0-2026-10-10.txt
```

The command prompt version saves through tmux's buffer; shell redirection (`>`) only works when the command runs in a shell. Both examples create or replace the named file. Use a filename that identifies the session, window, pane, and date, such as `storage-strategy-window-1-pane-0-2026-10-10.txt`.

`:.0` targets pane index 0 in the current window. To confirm which pane is farthest left, inspect pane indexes and horizontal positions with `tmux list-panes -F '#{pane_index} #{pane_left} #{pane_current_command}'`, then substitute the index of the leftmost pane if needed. Use `-S -` instead of `-S -5000` to capture all available tmux history (currently limited to 50,000 lines by `history-limit`).

To copy the current pane's available history directly to the macOS clipboard, run this from a shell inside that pane:

```bash
tmux capture-pane -p -t "$TMUX_PANE" -S - | pbcopy
```

Omit `-S -` to copy only the visible screen. To copy the previous command text in zsh, run `fc -ln -1 | pbcopy`; this copies the command you typed, not its output. Tmux does not track command-output boundaries, so select output in copy mode and press `y` to copy a specific region, or capture a known number of trailing lines.

---

## Plugin Management

### Installing Plugins
1. Add plugin to `tmux.conf` with `set -g @plugin '...'`
2. Press `Prefix+I` to install
3. Press `Prefix+U` to update all plugins

### Plugin Manager (TPM)
- Location: `~/.config/tmux/plugins/tpm`
- Auto-loaded at end of `tmux.conf`

---

## Documentation

### Troubleshooting
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Comprehensive guide for debugging tmux issues
  - Common problems and symptoms
  - Step-by-step debugging techniques
  - Fix procedures with examples
  - Preventive measures
  - Quick reference commands
  - Plugin-specific issues

### TODO
- **[TODO.md](docs/TODO.md)** - Planned improvements and known issues

### Decisions
- **[ADR 011](docs/adr/011-contextual-agent-notifications.md)** - Contextual Claude Code and Codex notification titles, previews, and project sounds

---

## Resources
- [Josean Martinez's Guide](https://www.josean.com/posts/tmux-setup)
- [tmux-agent-sidebar Plugin](https://github.com/hiroppy/tmux-agent-sidebar)
- [TPM (Plugin Manager)](https://github.com/tmux-plugins/tpm)
- [Additional configs](https://github.com/omerxx/dotfiles/blob/master/tmux/)
