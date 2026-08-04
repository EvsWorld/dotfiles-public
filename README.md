# Public Dotfiles

This repo is a public snapshot of a heavily customized macOS workflow system I have been refining over time.

The most substantial parts are a large `karabiner.edn` remapping setup, a custom `zsh` workflow layer, heavily tuned `tmux` behavior, and a modular Neovim configuration. Together they make up the shell, keyboard, terminal, and editor environment I use every day.

This is not meant to be a one-command bootstrap for someone else's machine. It is primarily a referenceable, sanitized version of the parts of my setup that are most worth sharing.

## What This Repo Is

This repo exists to publish the parts of my private dotfiles that are both:

- technically interesting enough to be useful as reference
- safe to share publicly after sanitization

It is less about "here are my dotfiles" and more about how I have designed my local workflow across input, navigation, session management, and editing.

## Core Areas

### Karabiner

`dotfiles/.config/karabiner.edn`

This is one of the most customized parts of the repo.

- Large Goku/Karabiner configuration with reusable modifiers, layers, simlayers, and templates
- Extensive app-specific behavior for terminal apps, browsers, editors, chat apps, and macOS utilities
- Hyper-key driven navigation and command workflows
- Keyboard Maestro, AppleScript, and shell integration where native shortcuts are weak or inconsistent

If you know Karabiner, this file is the clearest signal of how much thought has gone into the overall system.

### Zsh

`dotfiles/.zshrc`  
`dotfiles/.config/oh-my-zsh/custom/aliases.zsh`

My shell setup is more than aliases and prompt tweaks.

- Custom aliases and functions built around navigation, editing, search, and project work
- Workflow helpers for tmux session cleanup, orphaned Neovim processes, and script syncing
- Shell ergonomics tuned around actual usage, including keybinding conflict fixes and completion improvements
- A custom theme and shell behavior shaped around long-running terminal use

The shell layer is one of the areas I have iterated on the most.

### tmux

- `dotfiles/.config/tmux/tmux.conf`
- `dotfiles/.config/tmux/bindings.conf`
- `dotfiles/.config/tmux/scripts/`

The tmux config is built around fast movement, low-friction window management, and better long-running session hygiene.

- Vim-aware pane navigation and scrolling behavior
- Custom keybinding model, including no-prefix navigation for common actions
- Session and pane management tuned for multi-project terminal workflows
- Status line and plugin setup focused on visibility, recovery, and ergonomics

This is not stock tmux with a theme added. It reflects a lot of accumulated iteration.

### Neovim

`dotfiles/.config/nvim/`

My Neovim setup is modular and workflow-oriented rather than minimal for its own sake.

- Modular Lua configuration with separated options, keymaps, bootstrap, and plugin loading
- Pinned plugins via `lazy-lock.json`
- Customizations around navigation, LSP/completion, Git tooling, notes, AI tools, and terminal integration
- Built to fit the surrounding tmux, shell, and keyboard workflow instead of acting as a standalone editor island

## Supporting Pieces

### Ghostty

`dotfiles/.config/ghostty/config`

Terminal configuration that supports the rest of the workflow, including theme choices, keybindings, and tmux-friendly behavior.

### Alfred

`dotfiles/alfred/`

This section is intentionally lightweight.

- Includes a generated list of Alfred workflows I use
- Does not include actual workflow bundles, since those may contain secrets, tokens, or personal configuration

I keep it here as supporting workflow context, not as the main attraction of the repo.

## Public Snapshot Notes

These files are synced from a private setup and sanitized for public sharing.

Examples of things that are cleaned or replaced:

- username-based paths replaced with `$HOME`
- hostname values replaced with `YOUR-HOSTNAME.local`
- private vault paths replaced with safer placeholders

Some files are intentionally omitted because they are either too machine-specific or too sensitive to publish directly.

The repo also includes a helper script, `sync-dotfiles.sh`, which handles copying and sanitizing files before publishing. Its source manifest is an explicit allowlist: only listed files are copied. Before changing the public snapshot, the script validates the entire allowlist and stops if any source is missing. This prevents a retired private file from silently leaving a stale public copy behind.

## Using This Repo

If you want to borrow ideas from this repo, the best approach is to treat it as reference material rather than a drop-in setup.

- Read the Karabiner, Zsh, tmux, and Neovim configs directly
- Copy the patterns that fit your own workflow
- Adjust any placeholders, paths, and machine-specific assumptions for your system

Some external tools and plugins are required if you want to reuse pieces of the setup, including:

- Oh My Zsh
- Karabiner-Elements and Goku
- tmux and TPM
- Ghostty
- Neovim and `lazy.nvim`
- utilities such as `fzf`, `zoxide`, and `eza`

## License

Feel free to use these configurations as inspiration for your own setup.
