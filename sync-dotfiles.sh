#!/opt/homebrew/bin/bash

# Sync and sanitize dotfiles for public sharing
# Usage: Run this script from anywhere with: cfg publish-dotfiles

set -e  # Exit on error

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
    ["$HOME/.config/tmux/tmux.reset.conf"]="dotfiles/.config/tmux/tmux.reset.conf"
    ["$HOME/.config/oh-my-zsh/custom/aliases.zsh"]="dotfiles/.config/oh-my-zsh/custom/aliases.zsh"
    ["$HOME/.config/oh-my-zsh/custom/evan_robbyrussell_theme.zsh-theme"]="dotfiles/.config/oh-my-zsh/custom/evan_robbyrussell_theme.zsh-theme"
    ["$HOME/.config/ghostty/config"]="dotfiles/.config/ghostty/config"
    ["$HOME/.config/karabiner.edn"]="dotfiles/.config/karabiner.edn"
    ["$HOME/.config/nvim/init.lua"]="dotfiles/.config/nvim/init.lua"
    ["$HOME/.config/nvim/lua/lazy-bootstrap.lua"]="dotfiles/.config/nvim/lua/lazy-bootstrap.lua"
    ["$HOME/.config/nvim/lua/lazy-plugins.lua"]="dotfiles/.config/nvim/lua/lazy-plugins.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/interestingwords.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/interestingwords.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/auto-save.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/auto-save.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/harpoon.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/harpoon.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/mini.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/mini.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/nvim-tmux-navigation.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/nvim-tmux-navigation.lua"
    ["$HOME/.config/nvim/lua/kickstart/plugins/telescope.lua"]="dotfiles/.config/nvim/lua/kickstart/plugins/telescope.lua"
    ["$HOME/.config/nvim/lua/options.lua"]="dotfiles/.config/nvim/lua/options.lua"
    ["$HOME/.config/nvim/lua/keyremaps.lua"]="dotfiles/.config/nvim/lua/keyremaps.lua"
)

# Sanitization function
sanitize_file() {
    local file="$1"

    # Replace personal username with $HOME
    sed -i.bak "s|/Users/$MY_USERNAME|\$HOME|g" "$file"

    # Replace personal hostname with placeholder
    sed -i.bak "s/\"$MY_HOSTNAME\"/\"YOUR-HOSTNAME.local\"/g" "$file"
    sed -i.bak "s/'$MY_HOSTNAME'/'YOUR-HOSTNAME.local'/g" "$file"

    # Clean up backup files
    rm -f "$file.bak"
}

# Copy and sanitize each file
for src in "${!FILES[@]}"; do
    dest="${FILES[$src]}"

    if [ ! -f "$src" ]; then
        echo "⚠️  WARNING: Source file not found: $src"
        continue
    fi

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
echo "========================================="
echo "Committing changes..."
echo "========================================="
echo ""

# Git operations
if [ -d .git ]; then
    # Add all changes
    git add -A

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        echo "✓ No changes to commit - files are already up to date"
    else
        # Commit with timestamp
        timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        git commit -m "Update dotfiles snapshot - $timestamp"
        echo "✓ Changes committed with timestamp: $timestamp"
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
