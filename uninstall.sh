#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Uninstalling dotfiles..."

# Unstow all packages
echo "Unlinking config packages..."
stow --delete --verbose --target ~ \
    alacritty amethyst helix k9s starship tmux bat nvim ghostty zellij lazygit yazi

# Remove tat script symlink
if [ -L ~/bin/tat ]; then
    echo "Unlinking tat script..."
    rm ~/bin/tat
fi

# Remove source line from ~/.zshrc
SOURCE_LINE="source $DOTFILES_DIR/zsh/zshrc"
if [ -f ~/.zshrc ] && grep -qF "$SOURCE_LINE" ~/.zshrc; then
    echo "Removing source line from ~/.zshrc..."
    grep -vF "$SOURCE_LINE" ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc
    # Also remove the comment if it's now orphaned
    sed -i '' '/^# dotfiles$/d' ~/.zshrc 2>/dev/null || true
fi

echo ""
echo "Done!"
