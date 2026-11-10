#!/opt/homebrew/bin/bash

# Sync and sanitize dotfiles for public sharing
# Usage: Run this script from anywhere with: cfg publish-dotfiles
# test Jan 21 Wed  05:37 

set -e  # Exit on error

# Accept optional commit message parameter
CUSTOM_COMMIT_MSG="$1"

# Unset git environment variables that might be inherited from cfg bare repo alias
# This ensures git commands in this script operate on the local .git directory
unset GIT_DIR
unset GIT_WORK_TREE

# Auto-detect repository directory
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

# Load configuration
CONFIG_FILE="$REPO_DIR/.sync-config"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ ERROR: Configuration file not found: $CONFIG_FILE"
    echo ""
    echo "Please create .sync-config based on .sync-config.example:"
    echo "  cp .sync-config.example .sync-config"
    echo "  # Then edit .sync-config with your personal info"
    echo ""
    exit 1
fi

source "$CONFIG_FILE"

# Validate required config variables
if [ -z "$MY_USERNAME" ] || [ -z "$MY_HOSTNAME" ]; then
    echo "❌ ERROR: Missing required configuration variables"
    echo "Please set MY_USERNAME and MY_HOSTNAME in .sync-config"
    exit 1
fi

echo "========================================="
echo "Syncing dotfiles to public repo..."
echo "========================================="
echo ""

# Define source files and their destinations
declare -A FILES=(
    ["$HOME/.zshrc"]="dotfiles/.zshrc"
    ["$HOME/.config/tmux/tmux.conf"]="dotfiles/.config/tmux/tmux.conf"
    ["$HOME/.config/tmux/bindings.conf"]="dotfiles/.config/tmux/bindings.conf"
    ["$HOME/.config/tmux/scripts/keys.sh"]="dotfiles/.config/tmux/scripts/keys.sh"
    ["$HOME/.config/tmux/scripts/floax-left.sh"]="dotfiles/.config/tmux/scripts/floax-left.sh"
    ["$HOME/.config/tmux/scripts/move-pane-and-equalize.sh"]="dotfiles/.config/tmux/scripts/move-pane-and-equalize.sh"
    ["$HOME/.config/tmux/scripts/reorder-window.sh"]="dotfiles/.config/tmux/scripts/reorder-window.sh"
    ["$HOME/.config/tmux/scripts/normalize-prose.sh"]="dotfiles/.config/tmux/scripts/normalize-prose.sh"
    ["$HOME/.config/oh-my-zsh/custom/aliases.zsh"]="dotfiles/.config/oh-my-zsh/custom/aliases.zsh"
    ["$HOME/.config/oh-my-zsh/custom/evan_robbyrussell_theme.zsh-theme"]="dotfiles/.config/oh-my-zsh/custom/evan_robbyrussell_theme.zsh-theme"
    ["$HOME/.config/ghostty/config"]="dotfiles/.config/ghostty/config"
    ["$HOME/.config/karabiner.edn"]="dotfiles/.config/karabiner.edn"
    ["$HOME/.config/nvim/init.lua"]="dotfiles/.config/nvim/init.lua"
    ["$HOME/.config/nvim/lua/lazy-bootstrap.lua"]="dotfiles/.config/nvim/lua/lazy-bootstrap.lua"
    ["$HOME/.config/nvim/lua/lazy-plugins.lua"]="dotfiles/.config/nvim/lua/lazy-plugins.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/interestingwords.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/interestingwords.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/catppuccin.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/catppuccin.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/conform.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/conform.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/harpoon.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/harpoon.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/lint.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/lint.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/lspconfig.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/lspconfig.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/mini.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/mini.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/nvim-tmux-navigation.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/nvim-tmux-navigation.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/telescope.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/telescope.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/alpha-dashboard.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/alpha-dashboard.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/avante.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/avante.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/blink-cmp.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/blink-cmp.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/copilot.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/copilot.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/debug.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/debug.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/diffview.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/diffview.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/gemini.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/gemini.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/git-conflict.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/git-conflict.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/gitsigns.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/gitsigns.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/indent_line.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/indent_line.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/markdown-preview.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/markdown-preview.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/neo-tree.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/neo-tree.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/obsidian.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/obsidian.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/oil.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/oil.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/outline.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/outline.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/scrollview.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/scrollview.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/smart-splits.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/smart-splits.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/statusline.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/statusline.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/todo-comments.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/todo-comments.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/tokyonight.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/tokyonight.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/treesitter.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/treesitter.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/undotree.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/undotree.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/vim-apm.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/vim-apm.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/which-key.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/which-key.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/render-markdown.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/render-markdown.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/spider.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/spider.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/vim-eunuch.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/vim-eunuch.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/code-bridge.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/code-bridge.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/colorful-winsep.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/colorful-winsep.lua"
    ["$HOME/.config/nvim/lua/kickstart/health.lua"]="dotfiles/.config/nvim/lua/kickstart/health.lua"
    ["$HOME/.config/nvim/lua/custom/plugins/init.lua"]="dotfiles/.config/nvim/lua/custom/plugins/init.lua"
    ["$HOME/.config/nvim/lazy-lock.json"]="dotfiles/.config/nvim/lazy-lock.json"
    ["$HOME/.config/nvim/lua/options.lua"]="dotfiles/.config/nvim/lua/options.lua"
    ["$HOME/.config/nvim/lua/keyremaps.lua"]="dotfiles/.config/nvim/lua/keyremaps.lua"
    ["$HOME/.config/tmux/README.md"]="dotfiles/.config/tmux/README.md"
    ["$HOME/.config/nvim/README.md"]="dotfiles/.config/nvim/README.md"
    ["$HOME/.config/ghostty/README.md"]="dotfiles/.config/ghostty/README.md"
    # Files the published configs call directly
    ["$HOME/.config/nvim/lua/kickstart/plugins/no-neck-pain.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/no-neck-pain.lua"
    ["$HOME/.config/nvim/lua/custom/plugins/sessions.lua"]="dotfiles/.config/nvim/lua/custom/plugins/sessions.lua"
    ["$HOME/.config/tmux/scripts/equalize-preserve-sidebar.sh"]="dotfiles/.config/tmux/scripts/equalize-preserve-sidebar.sh"
    ["$HOME/.config/tmux/scripts/sesh.sh"]="dotfiles/.config/tmux/scripts/sesh.sh"
    ["$HOME/.config/sesh/sesh.toml"]="dotfiles/.config/sesh/sesh.toml"
    ["$HOME/.config/tmux/scripts/open-url-with-copy.sh"]="dotfiles/.config/tmux/scripts/open-url-with-copy.sh"
    ["$HOME/.config/tmux/scripts/copy-from-claude.py"]="dotfiles/.config/tmux/scripts/copy-from-claude.py"
    ["$HOME/scripts/tmux-theme-sync"]="dotfiles/scripts/tmux-theme-sync"
    ["$HOME/scripts/system-appearance"]="dotfiles/scripts/system-appearance"
    ["$HOME/.config/lazygit/config.yml"]="dotfiles/.config/lazygit/config.yml"
    # Claude Code and Codex hooks
    ["$HOME/scripts/llm-hook-block-dangerous.sh"]="dotfiles/scripts/llm-hook-block-dangerous.sh"
    ["$HOME/scripts/llm-hook-session-log.sh"]="dotfiles/scripts/llm-hook-session-log.sh"
    ["$HOME/scripts/llm-hook-session-end.sh"]="dotfiles/scripts/llm-hook-session-end.sh"
    # Shell, editor, and git support files
    ["$HOME/.config/tmux/scripts/tmux-sessionizer"]="dotfiles/.config/tmux/scripts/tmux-sessionizer"
    ["$HOME/.zshenv"]="dotfiles/.zshenv"
    ["$HOME/.zprofile"]="dotfiles/.zprofile"
    ["$HOME/.config/nvim/.stylua.toml"]="dotfiles/.config/nvim/.stylua.toml"
    ["$HOME/.config/nvim/snippets/global.json"]="dotfiles/.config/nvim/snippets/global.json"
    ["$HOME/.config/nvim/snippets/lua.json"]="dotfiles/.config/nvim/snippets/lua.json"
    ["$HOME/.gitignore_global"]="dotfiles/.gitignore_global"
    # tmux ADRs, listed one by one so new ADRs stay opt-in. 011 is held back
    # because it names private projects.
    ["$HOME/.config/tmux/docs/adr/001-session-order-bindings.md"]="dotfiles/.config/tmux/docs/adr/001-session-order-bindings.md"
    ["$HOME/.config/tmux/docs/adr/002-pane-border-visibility.md"]="dotfiles/.config/tmux/docs/adr/002-pane-border-visibility.md"
    ["$HOME/.config/tmux/docs/adr/003-layout-only-session-restore.md"]="dotfiles/.config/tmux/docs/adr/003-layout-only-session-restore.md"
    ["$HOME/.config/tmux/docs/adr/004-single-bindings-file.md"]="dotfiles/.config/tmux/docs/adr/004-single-bindings-file.md"
    ["$HOME/.config/tmux/docs/adr/005-delegate-yank-to-tmux-yank.md"]="dotfiles/.config/tmux/docs/adr/005-delegate-yank-to-tmux-yank.md"
    ["$HOME/.config/tmux/docs/adr/006-mouse-scroll-no-exit-copy-mode.md"]="dotfiles/.config/tmux/docs/adr/006-mouse-scroll-no-exit-copy-mode.md"
    ["$HOME/.config/tmux/docs/adr/007-route-scroll-keys-by-alternate-screen.md"]="dotfiles/.config/tmux/docs/adr/007-route-scroll-keys-by-alternate-screen.md"
    ["$HOME/.config/tmux/docs/adr/008-no-prefix-copy-mode-search.md"]="dotfiles/.config/tmux/docs/adr/008-no-prefix-copy-mode-search.md"
    ["$HOME/.config/tmux/docs/adr/009-sessionx-fast-custom-paths.md"]="dotfiles/.config/tmux/docs/adr/009-sessionx-fast-custom-paths.md"
    ["$HOME/.config/tmux/docs/adr/010-clean-prose-copy.md"]="dotfiles/.config/tmux/docs/adr/010-clean-prose-copy.md"
    ["$HOME/.config/tmux/docs/adr/012-sessionx-session-recency-fork.md"]="dotfiles/.config/tmux/docs/adr/012-sessionx-session-recency-fork.md"
    ["$HOME/.config/tmux/docs/adr/013-sessionx-secondary-launch-binding.md"]="dotfiles/.config/tmux/docs/adr/013-sessionx-secondary-launch-binding.md"
    ["$HOME/.config/tmux/docs/adr/014-native-binding-notes.md"]="dotfiles/.config/tmux/docs/adr/014-native-binding-notes.md"
    ["$HOME/.config/tmux/docs/adr/015-single-clipboard-writer.md"]="dotfiles/.config/tmux/docs/adr/015-single-clipboard-writer.md"
    ["$HOME/.config/tmux/docs/adr/016-floax-left-pane-is-project-pane.md"]="dotfiles/.config/tmux/docs/adr/016-floax-left-pane-is-project-pane.md"
    ["$HOME/.config/tmux/docs/adr/017-retire-sessionx-for-sesh.md"]="dotfiles/.config/tmux/docs/adr/017-retire-sessionx-for-sesh.md"
    ["$HOME/.config/tmux/docs/adr/018-enable-automatic-rename-for-nerd-font-window-icons.md"]="dotfiles/.config/tmux/docs/adr/018-enable-automatic-rename-for-nerd-font-window-icons.md"
    ["$HOME/.config/tmux/docs/adr/019-remove-nerd-font-window-name-active-pane-only.md"]="dotfiles/.config/tmux/docs/adr/019-remove-nerd-font-window-name-active-pane-only.md"
    ["$HOME/.config/tmux/docs/adr/020-disable-agent-sidebar-trial.md"]="dotfiles/.config/tmux/docs/adr/020-disable-agent-sidebar-trial.md"
    # TODO: add these, and others similar, if applicable
)

# Validate the complete allowlist before changing the public snapshot. A missing
# source usually means the private config was moved or retired; continuing would
# leave its old public copy behind and make the snapshot silently stale.
missing_sources=()
for src in "${!FILES[@]}"; do
    if [ ! -f "$src" ]; then
        missing_sources+=("$src")
    fi
done

if [ "${#missing_sources[@]}" -gt 0 ]; then
    echo "❌ ERROR: Allowlisted source files are missing:"
    printf '  - %s\n' "${missing_sources[@]}"
    echo ""
    echo "No files were copied or committed."
    echo "Restore each source, or remove its allowlist entry and public copy."
    exit 1
fi

# Paths that must never be published, even if they appear in this repo.
EXCLUDED_PATHS=(
    "scripts/network-scan"
    "dotfiles/scripts/network-scan"
)

# Strings that must never appear in the published snapshot, in any form.
# Matched case-insensitively as fixed strings; the short hostname also
# catches the fully qualified one.
LEAK_PATTERNS=(
    "$MY_USERNAME"
    "${MY_HOSTNAME%.local}"
    "iCloud~md~obsidian"
)
if [ -n "${MY_ORG:-}" ]; then
    LEAK_PATTERNS+=("$MY_ORG")
fi
for term in "${!MY_PRIVATE_TERMS[@]}"; do
    LEAK_PATTERNS+=("$term")
done

# Sanitization function
sanitize_file() {
    local file="$1"

    # Replace personal username with $HOME
    sed -i.bak "s|/Users/$MY_USERNAME|\$HOME|g" "$file"

    # Replace personal hostname with placeholder
    sed -i.bak "s/\"$MY_HOSTNAME\"/\"YOUR-HOSTNAME.local\"/g" "$file"
    sed -i.bak "s/'$MY_HOSTNAME'/'YOUR-HOSTNAME.local'/g" "$file"

    # Sanitize Obsidian vault path (iCloud specific). Matches the ~/ and $HOME/
    # forms (/Users/<name>/ was already rewritten to $HOME above) and keeps
    # the prefix so the public path expands the same way.
    sed -i.bak -E "s#(~|[\$]HOME)/Library/Mobile Documents/iCloud~md~obsidian/Documents/[^'\"]*#\1/Documents/ObsidianVault#g" "$file"

    # Replace employer name, keeping its casing. Mixed casings are left for
    # the leak check to catch.
    if [ -n "${MY_ORG:-}" ]; then
        local org="${MY_ORG,,}"
        sed -i.bak -e "s/${org^^}/EMPLOYER/g" -e "s/${org^}/Employer/g" -e "s/$org/employer/g" "$file"
    fi

    # Replace other private terms (such as project names) with their
    # configured stand-ins.
    for term in "${!MY_PRIVATE_TERMS[@]}"; do
        sed -i.bak "s/$term/${MY_PRIVATE_TERMS[$term]}/g" "$file"
    done

    # Clean up backup files
    rm -f "$file.bak"
}

# Copy and sanitize each file
for src in "${!FILES[@]}"; do
    dest="${FILES[$src]}"

    # Create destination directory if needed
    dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"

    # Copy file
    cp "$src" "$dest"
    echo "✓ Copied: $dest"

    # Sanitize
    sanitize_file "$dest"
    echo "  → Sanitized personal data"
done

echo ""

# Generate Alfred workflow showcase if enabled
if [ "${GENERATE_ALFRED_SHOWCASE:-false}" = true ]; then
    echo "========================================="
    echo "Generating Alfred Workflows Showcase..."
    echo "========================================="
    echo ""
    ./generate-alfred-showcase.sh
fi

# Remove excluded content from the public repo before staging.
for excluded_path in "${EXCLUDED_PATHS[@]}"; do
    if [ -e "$excluded_path" ]; then
        rm -rf "$excluded_path"
        echo "✓ Removed excluded path: $excluded_path"
    fi
done

echo ""
echo "========================================="
echo "Committing changes..."
echo "========================================="
echo ""

# Git operations
if [ -d .git ]; then
    # Verify the sanitized snapshot before staging anything. The sed rules
    # only catch the forms they anticipate; this scans everything git add -A
    # would stage. This script is excluded because its own rules contain
    # the patterns.
    leak_args=()
    for pattern in "${LEAK_PATTERNS[@]}"; do
        leak_args+=(-e "$pattern")
    done

    leaks=$(git grep -nIiF --untracked "${leak_args[@]}" -- . ':(exclude)sync-dotfiles.sh') \
        && leak_status=0 || leak_status=$?

    if [ "$leak_status" -eq 0 ]; then
        echo "❌ ERROR: Personal data survived sanitization:"
        echo "$leaks"
        echo ""
        echo "Files were copied for inspection, but nothing was staged or committed."
        echo "Add a sanitize rule or fix the source file, then rerun."
        exit 1
    elif [ "$leak_status" -ne 1 ]; then
        echo "❌ ERROR: Leak check failed to run (git grep exit $leak_status)"
        exit 1
    fi

    # Add all changes
    git add -A -- . \
        ':(exclude)scripts/network-scan/**' \
        ':(exclude)dotfiles/scripts/network-scan/**'

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        echo "✓ No changes to commit - files are already up to date"
    else
        # Use custom message if provided, otherwise use timestamp
        if [ -n "$CUSTOM_COMMIT_MSG" ]; then
            COMMIT_MSG="$CUSTOM_COMMIT_MSG"
        else
            COMMIT_MSG="Update dotfiles snapshot - $(date '+%Y-%m-%d %H:%M:%S')"
        fi

        git commit -m "$COMMIT_MSG"
        echo "✓ Changes committed: $COMMIT_MSG"
    fi
else
    echo "⚠️  WARNING: Not a git repository. Run 'git init' first."
fi

echo ""
echo "========================================="
echo "✓ Sync complete!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Review changes: git log -1 --stat"
echo "  2. Push to GitHub: git push"
echo ""
