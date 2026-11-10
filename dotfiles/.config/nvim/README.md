# Neovim Configuration

Personal Neovim configuration based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim), organized as a modular Lua configuration.

## Source of Truth

- Entry point: [`init.lua`](./init.lua)
- Options: [`lua/options.lua`](./lua/options.lua)
- Keymaps: [`lua/keyremaps.lua`](./lua/keyremaps.lua)
- Plugin specifications: [`lua/kickstart/plugins/`](./lua/kickstart/plugins/)
- Decisions and implementation notes: [`docs/`](./docs/)

Keybindings are not duplicated here.
The `desc` field on each mapping is the source of truth, surfaced by which-key, `:map`, and `:Telescope keymaps`.
Placement rationale lives in [the keybinding design principles](./docs/2026-07-28-keybinding-design-principles.md).

## Requirements

Required command-line tools:

- `git`, used to bootstrap and install plugins.
- `ripgrep`, used by Telescope for content searches.
- `fd`, used by Telescope for file discovery.
- `make` and a C compiler, used to build `telescope-fzf-native`.
- A Nerd Font, because `vim.g.have_nerd_font` is enabled.

Language servers, formatters, and linters are installed through Mason.
The configured tool list lives in [`lua/kickstart/plugins/lspconfig.lua`](./lua/kickstart/plugins/lspconfig.lua).

## Plugin Organization

- [`lua/lazy-bootstrap.lua`](./lua/lazy-bootstrap.lua) installs and prepends `lazy.nvim`.
- [`lua/lazy-plugins.lua`](./lua/lazy-plugins.lua) configures lazy.nvim and registers the plugin specs.
- [`lua/kickstart/plugins/`](./lua/kickstart/plugins/) contains the main plugin specifications.
- [`lua/custom/plugins/`](./lua/custom/plugins/) contains personal extensions and is auto-imported by lazy.nvim.
- [`lazy-lock.json`](./lazy-lock.json) records the exact plugin revisions.

Most plugin specs return a table containing the repository, loading conditions, dependencies, and configuration.

## Adding A Plugin

For a personal plugin, create `lua/custom/plugins/name.lua`:

```lua
return {
  {
    'owner/plugin-name',
    event = 'VeryLazy',
    opts = {},
  },
}
```

The `lua/custom/plugins/` directory is already imported by `lua/lazy-plugins.lua`, so no additional `require` is needed.

For a plugin under `lua/kickstart/plugins/`, create the spec there and add `require 'kickstart.plugins.name'` to `lua/lazy-plugins.lua`.

Use `:Lazy` to inspect plugin status and `:Lazy sync` after changing plugin specs.

## Current Behavior

### Saving

- There is no autosave.
- Format-on-save is disabled, so plain saves never reformat buffers.
- Unsaved buffers show a red `● UNSAVED` marker beside their path, including in inactive windows.
- Buffers without local edits automatically reload when the file changes on disk.
- Buffers with unsaved edits show Vim's standard W12 warning.
- Oil saves buffers changed by an LSP file operation only when they were unmodified before that operation.

See [the autosave retirement note](./docs/2026-07-11-retire-autosave-external-file-guard.md).
For Markdown opening and Oil preview troubleshooting, see [the picker and preview note](./docs/2026-09-18-obsidian-picker-and-oil-preview.md).

### Cursor

The cursor blinks only in Insert mode, with an 800 ms delay before blinking and 700 ms visible and hidden intervals.
Insert mode uses Neovim's default vertical-line cursor, while other modes retain their default cursor shapes without blinking.

### Statusline

Each window has its own statusline.
The filename uses an absolute path with `~` for the home directory, shortens intermediate directories as the window narrows, and eventually drops leading path segments while preserving the filename and unsaved marker.
Inactive splits reserve only the space needed by their location component, so they can show more of the path than active splits at the same width.
The focused split uses lavender separators and a contrasting background: `crust` against inactive `surface0` in dark mode, or near-white `base` against gray `surface1` in light mode.
Only the focused split shows its cursor line, and light mode overrides that cursor line to `surface0` so it stays visible against the near-white active background.
Floating windows are excluded from the focus treatment and theme themselves, so Telescope and Harpoon keep their own colors.

See [the statusline path decision note](./docs/2026-08-30-statusline-full-path-display.md).

### Search and Clipboard

- Yank mappings have copy and append variants.
- Visual yanks include the file path and line range as context.
- Visual search returns to Normal mode so `n` and `N` navigate the matches.
- `n` and `N` always follow the latest `/` or `?` search.
- `:Rename`, `:CopyFileName`, and `:CopyParentDirectory` provide file and path utilities.

See [the yank and search note](./docs/2026-07-08-visual-yank-and-search-keymaps.md) and [the search navigation note](./docs/2026-07-13-latest-search-owns-n-navigation.md).

### Telescope and Obsidian

Retrieval mappings are action-first:

- `<leader>f…` finds files by name.
- `<leader>s…` searches file contents.
- `<leader>o…` handles Obsidian-aware note operations.

File searches skip gitignored files.
In the general file pickers, `<M-i>` reruns the search with them included, still skipping dependency and cache folders such as `node_modules`, and pressing it again switches back.

The current launch directory supplies Neovim's initial root, and sessions
restore layouts without saving directory changes while the `curdir` omission
is being tried.
Telescope's project searches follow the effective cwd, while its local
searches use the current file or Oil directory.
See [the cwd and session policy](./docs/2026-09-23-neovim-cwd-oil-telescope-session-policy.md).

In Oil, `_` goes up one level, except at the root of a directory that the launch directory symlinks to, where it returns to the launch directory.
`-` always opens the launch directory.
See [the symlink hub note](./docs/2026-10-25-oil-parent-returns-to-symlink-hub.md).

`<leader>ss` passes everything after a quoted pattern to ripgrep: `<C-k>` quotes the prompt, `<C-l>` also adds `-F` for literal text, and `<C-g>` and `<C-t>` add `--glob` and `-t`.
Grep results can be appended to the global quickfix list while preserving the grep prompt as the active search highlight.
`:QfToFile` saves the quickfix list to the launch directory as `YYYY_MM_DD-HHMMSS-quickfix.txt`, which `:cfile` reloads.
The selected Telescope result uses a bold, lavender-caret row, and Harpoon opens as a centered, rounded menu at 90% of the editor width.

See [the search naming convention](./docs/2026-07-13-telescope-obsidian-search-convention.md) and [the quickfix handoff note](./docs/2026-07-06-telescope-quickfix-append.md).
`<leader>soc` opens a temporary menu of vault audits for the PK-14 standardization; see [the audit picker note](./docs/2026_11_03-vault-audit-picker.md).

### Movement

Vertical movement follows visible display lines, including wrapped Markdown.
Line-boundary mappings follow logical source lines and target nonblank characters, while their `g`-prefixed variants reach display-line boundaries.
Karabiner q-mode retains its character, word, and line navigation and deletion behavior while Neovim is in Insert mode.

See [the wrapped-line navigation note](./docs/2026-08-01-wrapped-line-navigation.md) and [the line boundaries note](./docs/2026-09-05-line-boundaries-follow-logical-lines.md).

### Prose Reading

Markdown, text, and Avante buffers soft-wrap to the window width.
`textwidth` remains `0`, so wrapping never inserts characters into the file, and there are no wrap toggles.

Centering is manual and tab-scoped through No Neck Pain.
It narrows wide panes to a fixed reading measure and treats the padding windows as Neovim's edge so `<C-h>` and `<C-l>` still reach adjacent tmux panes.

See [the reading-measure note](./docs/2026-09-04-centered-markdown-reading-measure.md).

### Windows

All split, layout, and buffer-swap operations live under `<leader>w…`, mirroring tmux's `prefix w` namespace.
Swapping preserves each buffer's cursor and scroll position.
Zoom restores the prior split layout when toggled off.

See [the buffer-swap note](./docs/2026-07-15-buffer-swap-preserves-view-and-focus.md) and [ADR 027: Align Neovim and tmux Window Operations](./docs/../../../docs/adrs/027-align-neovim-and-tmux-window-operations.md).
Use `:map <leader>w` or `:Telescope keymaps` to browse all window operations.

### Undotree

Undotree uses stronger green, red, and amber diff highlights that are reapplied after colorscheme changes.
Use `<leader>u` to toggle the panel.

### AI Tooling

`avante.nvim` is dormant.
Its plugin specification remains in [`lua/kickstart/plugins/avante.lua`](./lua/kickstart/plugins/avante.lua) for reference, but it is not imported by [`lua/lazy-plugins.lua`](./lua/lazy-plugins.lua), so lazy.nvim does not register or load it.

## Maintenance

Keep this README focused on current behavior and navigation.
When behavior changes, update the relevant summary here and put detailed rationale in a dated note under [`docs/`](./docs/).
