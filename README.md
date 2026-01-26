# Public Dotfiles

test Jan 25 Sun  22:10
test Jan 25 Sun  22:14
test 2026_01_25_T22_16 

Periodic snapshots of my personal dotfiles, sanitized for public sharing.

## Included Files

- **`.zshrc`** - Zsh shell configuration with Oh My Zsh
- **`.config/tmux/tmux.conf`** - Tmux configuration with plugins
- **`.config/tmux/tmux.reset.conf`** - Tmux keybinding customizations
- **`.config/oh-my-zsh/custom/aliases.zsh`** - Custom shell aliases
- **`.config/ghostty/config`** - Ghostty terminal emulator configuration
- **`.config/nvim/`** - Neovim configuration
  - Core: `init.lua`, plugin loader, options, keymaps
  - 37 plugin configurations in `lua/kickstart/plugins/`
  - Custom plugins: `lua/custom/plugins/`
  - Plugin lock: `lazy-lock.json`
- **`alfred/`** - Alfred workflows showcase
  - **List only** - No actual workflow files (contain API keys)
  - See `alfred/workflows-i-use.md` for 110+ workflows I use
  - Find workflows on [Alfred Gallery](https://alfred.app/workflows/)

## Setup Notes

These dotfiles reference several external tools and plugins you'll need to install:

### Shell & Terminal
- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [Ghostty](https://ghostty.org/) - Fast terminal emulator
- [zoxide](https://github.com/ajeetdsouza/zoxide) - Smart directory navigation
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder

### Zsh Plugins
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)

### Tmux
- [TPM](https://github.com/tmux-plugins/tpm) - Tmux Plugin Manager
- Various tmux plugins (see `tmux.conf` for full list)

### Other Tools
- [eza](https://github.com/eza-community/eza) - Modern `ls` replacement
- [nvim](https://neovim.io/) - Neovim text editor

### Neovim
- [Neovim](https://neovim.io/) - v0.9+ required
- [lazy.nvim](https://github.com/folke/lazy.nvim) - Plugin manager (auto-bootstrapped)
- Plugins auto-install on first launch
- See `lazy-lock.json` for pinned versions

**Plugin Categories:**
- **LSP & Completion:** lspconfig, blink-cmp
- **Git:** gitsigns, git-conflict, diffview
- **Navigation:** telescope, harpoon, neo-tree, oil
- **UI:** tokyonight, alpha-dashboard, statusline, which-key
- **Editing:** treesitter, conform, lint, auto-save
- **AI:** copilot, avante, gemini
- **Notes:** obsidian.nvim
- **Utilities:** todo-comments, markdown-preview, undotree

## Sanitization

Personal information has been sanitized from these files:
- Username paths replaced with `$HOME`
- Hostname replaced with `YOUR-HOSTNAME.local`
- Obsidian iCloud vault path → `~/Documents/ObsidianVault`

You'll need to adjust these placeholders for your own system.

## Sync Process

These files are synced from my private dotfiles repo using an automated script (`sync-dotfiles.sh`) that:
1. Copies files from their source locations
2. Sanitizes personal data
3. Commits changes with a timestamp

Last synced: Check git log for latest commit date

### Setting Up Your Own Sync (Optional)

If you want to fork this repo and maintain your own public dotfiles:

1. **Create your config file:**
   ```bash
   cp .sync-config.example .sync-config
   # Edit .sync-config with your username and hostname
   ```

2. **Edit the source files list in `sync-dotfiles.sh`** to match your dotfiles locations

3. **Add a git alias** (optional, for convenience):
   ```bash
   git config alias.sync-dotfiles '!sh /path/to/this/repo/sync-dotfiles.sh'
   ```

   Or if using a bare repo setup like `cfg`:
   ```bash
   cfg config alias.publish-dotfiles '!sh /path/to/this/repo/sync-dotfiles.sh'
   ```

4. **Run the sync:**
   ```bash
   # With timestamp commit message (default):
   ./sync-dotfiles.sh
   # Or: cfg publish-dotfiles

   # With custom commit message:
   ./sync-dotfiles.sh "Add new vim keybindings"
   ```

The `.sync-config` file is gitignored, so your personal info stays private.

## Unified Commit Workflow (Advanced)

If you use a bare git repo for your private dotfiles (like the `cfg` setup), you can create a unified command that commits to both repos at once.

**The `ccump` shell function** (cfg commit + publish):
```bash
ccump "Add new vim keybindings"
```

This will:
1. Stage tracked files and commit to your private cfg bare repo
2. Run the sync script to sanitize and commit to this public repo
3. Use the same commit message for both commits

After running `ccump`, you still need to manually push both repos:
```bash
cfg push                                    # Push private repo
cd ~/Projects/dotfilesPublish && git push   # Push public repo
```

See the `ccump()` function in the dotfiles for implementation details.

## License

Feel free to use these configurations as inspiration for your own dotfiles.
