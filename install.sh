#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Stow all packages (XDG configs + tmux)
echo "Linking config packages..."
stow --restow --verbose --target ~ \
    alacritty amethyst helix k9s starship tmux bat nvim ghostty zellij lazygit yazi mise

# tat script to ~/bin
echo "Linking tat script..."
mkdir -p ~/bin
ln -sf "$DOTFILES_DIR/scripts/tat" ~/bin/tat

# Source zshrc from ~/.zshrc if not already present
SOURCE_LINE="source $DOTFILES_DIR/zsh/zshrc"
if [ -f ~/.zshrc ]; then
    if ! grep -qF "$SOURCE_LINE" ~/.zshrc; then
        echo "Adding source line to ~/.zshrc..."
        echo "" >> ~/.zshrc
        echo "# dotfiles" >> ~/.zshrc
        echo "$SOURCE_LINE" >> ~/.zshrc
    else
        echo "~/.zshrc already sources dotfiles"
    fi
else
    echo "Creating ~/.zshrc..."
    echo "# dotfiles" > ~/.zshrc
    echo "$SOURCE_LINE" >> ~/.zshrc
fi

# Install yazi packages
if command -v ya &> /dev/null; then
    echo "Installing yazi packages..."
    ya pkg install
else
    echo "Warning: ya not found, skipping yazi package installation"
fi

echo ""
echo "Done!"
