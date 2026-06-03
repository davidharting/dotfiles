#!/bin/bash
# Idempotent dotfiles installer. Safe to re-run anytime to sync changes.
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing dotfiles from $DOTFILES_DIR"

# Install brew packages
echo "Installing brew packages..."
brew bundle --file="$DOTFILES_DIR/Brewfile" --no-upgrade

# Back up and remove existing ~/.zshrc if it's a real file (not our symlink)
if [ -f ~/.zshrc ] && [ ! -L ~/.zshrc ]; then
  echo "Backing up existing ~/.zshrc to ~/.zshrc.bak..."
  mv ~/.zshrc ~/.zshrc.bak
fi

# Stow all packages
echo "Linking config packages..."
for dir in "$DOTFILES_DIR"/*/; do
  pkg="${dir%/}"
  pkg="${pkg##*/}"
  case "$pkg" in
    scripts | tests)
      continue
      ;;
  esac
  stow --restow --verbose --target ~ "$pkg"
done

echo "Linking agent instructions..."
mkdir -p ~/.codex ~/.claude
ln -sfn ~/.agents/AGENTS.md ~/.codex/AGENTS.md
ln -sfn ~/.agents/AGENTS.md ~/.claude/CLAUDE.md

# Stow scripts to ~/.dotfiles/bin
echo "Linking scripts..."
mkdir -p ~/.dotfiles/bin
stow --restow --verbose --target ~/.dotfiles/bin scripts

# Install yazi packages
if command -v ya &>/dev/null; then
  echo "Installing yazi packages..."
  ya pkg install
else
  echo "Warning: ya not found, skipping yazi package installation"
fi

# bearcli symlink
if [ -d "/Applications/Bear.app" ]; then
  mkdir -p ~/.local/bin
  ln -sf /Applications/Bear.app/Contents/MacOS/bearcli ~/.local/bin/bearcli
else
  echo "Warning: Bear.app not found, skipping bearcli symlink"
fi

# Apply macOS settings
"$DOTFILES_DIR/macos.sh"

echo ""
echo "Done!"
