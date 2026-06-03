#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Uninstalling dotfiles..."

echo "Unlinking agent instructions..."
rm -f ~/.codex/AGENTS.md ~/.claude/CLAUDE.md

# Unstow all packages
echo "Unlinking config packages..."
for dir in "$DOTFILES_DIR"/*/; do
  pkg="${dir%/}"
  pkg="${pkg##*/}"
  [[ "$pkg" == "scripts" ]] && continue
  stow --delete --verbose --target ~ "$pkg"
done

# Unstow scripts from ~/.dotfiles/bin
echo "Unlinking scripts..."
stow --delete --verbose --target ~/.dotfiles/bin scripts

echo ""
echo "Done!"
