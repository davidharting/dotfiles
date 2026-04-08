#!/usr/bin/env bash
set -e

echo "Applying macOS settings..."

# Reduce motion (requires sudo on modern macOS)
sudo defaults write com.apple.universalaccess reduceMotion -bool true

# Key repeat (1 = fastest)
defaults write NSGlobalDomain KeyRepeat -int 1

# Initial key repeat delay (10 = shortest)
defaults write NSGlobalDomain InitialKeyRepeat -int 10

echo "Done! Some settings require a logout or reboot to take effect."
