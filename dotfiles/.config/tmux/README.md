# Tmux Configuration

## Philosophy
- **Vim-aware navigation**: Seamless switching between vim and tmux panes
- **No prefix navigation**: Core movements (panes, windows, scrolling) work without prefix
- **Window operations mode**: `Prefix+w` enters a dedicated mode for window/pane management
- **Vi-style copy mode**: Familiar vim keybindings for text selection and copying

## Key Prefix
- **Prefix**: `Ctrl+Space`
- **Reload config**: `Prefix+r`

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

### Pane Resizing
- `Alt+Shift+h/j/k/l` - Resize panes (vim-aware)
- Also available: `Prefix+Alt+h/j/k/l` (alternative binding)

---

## Window Operations Mode (`Prefix+w`)

Enter window operations mode with `Prefix+w`, then:

### Splitting
- `v` - Split vertically (side-by-side panes)
- `d` - Split horizontally (stacked panes)

### Layout Management
- `w` - Toggle zoom current pane
- `e` - Equalize all panes
- `s` - Even horizontal layout
- `Shift+s` - Even vertical layout

### Pane Management
- `n` - Hide pane (moves to new background window)
- `m` - Move pane to window (prompts for target)
- `Shift+m` - Move pane interactively (choose window)

### Pane Swapping
- `h/j/k/l` - Swap with adjacent pane (left/down/up/right)

---

## Sessions & Windows

### Session Management
- `Prefix+f` - SessionX fuzzy finder (main session launcher)
- `Prefix+l` - Switch to last session
- `Prefix+$` - Rename session
- `Prefix+Ctrl+d` - Detach from session

### Window Management
- `Prefix+c` - New window (inherits current directory)
- `Prefix+R` - Rename window
- `Prefix+1-9` - Jump to window 1-9
- `Prefix+"` - Interactive window chooser (shows names)

### Pane Management
- `Prefix+Ctrl+c` - Close pane and auto-equalize remaining panes
- `Prefix+z` - Toggle pane zoom
- `Prefix+x` - Swap pane with next

---

## Copy Mode

### Entering Copy Mode
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
- `y` - Copy selection (stay in copy mode)
- `Shift+y` - Copy and exit copy mode
- Mouse drag - Copy selection

---

## Plugins & Features

### SessionX
- `Prefix+f` - Launch fuzzy session finder
- Zoxide integration enabled
- Shows subdirectories of custom paths
- `Ctrl+y` - Zoom session to new window

### Floax (Floating Terminal)
- `Prefix+i` - Toggle floating terminal window
- `Prefix+Shift+p` - Floax menu (resize, fullscreen options)
- Session name: `floax-floating-window`
- Size: 60% width × 80% height

### Other Plugins
- **vim-tmux-navigator** - Seamless vim/tmux pane navigation
- **tmux-resurrect** - Save/restore tmux sessions
- **tmux-continuum** - Auto-save sessions every 15 minutes
- **tmux-yank** - Copy to system clipboard
- **tmux-fzf-url** - `o` to open URLs from terminal
- **catppuccin-tmux** - Theme with custom pane borders

---

## Configuration Details

### Behavior
- Windows start at index 1 (not 0)
- Windows auto-renumber when closed
- Automatic window renaming disabled (manual naming encouraged)
- Don't exit tmux when closing last session
- Mouse support enabled
- History limit: 1 million lines

### Visual
- Status bar at top (macOS style)
- Terminal title shows session name
- Bright red active pane border
- Full-width yellow status bar in copy mode

---

## Tips & Best Practices

### Window Organization
- **Name your windows**: Use `Prefix+R` to rename windows for clarity
- **Use direct selection**: `Prefix+1-9` is faster than cycling once you know window positions
- **Keep it organized**: Logs in window 1, editor in 2, etc. Consistency reduces cognitive load

### When to Use What
- **SessionX** (`Prefix+f`): Switching between projects/session
- **Direct window selection** (`Prefix+1-9`): When you know where you're going
- **Window cycling** (`Alt+n/p/etc`): Browsing or finding something
- **Window chooser** (`Prefix+"`): When you forgot window names/numbers

### Pane Management Strategy
- Use `Prefix+w+e` frequently to equalize panes after splits
- `Prefix+w+n` to temporarily hide panes (they persist as background windows)
- `Prefix+Ctrl+c` to close panes (auto-equalizes remaining panes)

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

## Resources
- [Josean Martinez's Guide](https://www.josean.com/posts/tmux-setup)
- [SessionX Plugin](https://github.com/omerxx/tmux-sessionx)
- [TPM (Plugin Manager)](https://github.com/tmux-plugins/tpm)
- [Additional configs](https://github.com/omerxx/dotfiles/blob/master/tmux/)
