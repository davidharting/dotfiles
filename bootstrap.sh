#!/usr/bin/env bash
# Run once on a new machine to install prerequisites (Homebrew, mise, Herd Lite),
# then hands off to install.sh.
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Install Homebrew
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for the rest of this script (Apple Silicon path)
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew already installed"
fi

# Install mise
if ! command -v mise &>/dev/null; then
  echo "Installing mise..."
  curl https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
else
  echo "mise already installed"
fi

# Install Herd Lite (PHP)
if ! command -v php &>/dev/null || [[ ! -d "$HOME/.config/herd-lite" ]]; then
  echo "Installing Herd Lite..."
  /bin/bash -c "$(curl -fsSL https://php.new/install/mac)"
else
  echo "Herd Lite already installed"
fi

# Run dotfiles installer
"$DOTFILES_DIR/install.sh"

# Install mise tools
echo "Installing mise tools..."
mise install

# Sanity check: verify required apps are installed
"$DOTFILES_DIR/check-apps.sh"
