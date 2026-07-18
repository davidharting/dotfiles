#!/usr/bin/env bash
set -e

echo "Applying macOS settings..."

# Keyboard
# Key repeat (1 = fastest)
defaults write NSGlobalDomain KeyRepeat -int 1
# Initial key repeat delay (10 = shortest)
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Scrolling: disable natural scrolling (trackpad feels inverted on default)
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Animations
# Reduce motion (requires sudo on modern macOS)
sudo defaults write com.apple.universalaccess reduceMotion -bool true
# System-wide
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -int 0          # window open/close
defaults write NSGlobalDomain NSScrollAnimationEnabled -int 0                    # smooth scrolling
defaults write NSGlobalDomain QLPanelAnimationDuration -int 0                    # Quick Look panel
defaults write NSGlobalDomain NSScrollViewRubberbanding -int 0                   # rubber-band overscroll
defaults write NSGlobalDomain NSDocumentRevisionsWindowTransformAnimation -int 0 # document revision
defaults write NSGlobalDomain NSToolbarFullScreenAnimationDuration -int 0        # full-screen toolbar transition
defaults write NSGlobalDomain NSBrowserColumnAnimationSpeedMultiplier -int 0     # Finder column view
# Finder
defaults write com.apple.finder DisableAllAnimations -int 1
# Dock
defaults write com.apple.dock autohide-time-modifier -int 0
defaults write com.apple.dock autohide-delay -int 0
defaults write com.apple.dock launchanim -int 0         # no launch bounce
defaults write com.apple.dock mineffect -string "scale" # scale instead of genie
# Launchpad
defaults write com.apple.dock springboard-show-duration -int 0
defaults write com.apple.dock springboard-hide-duration -int 0
defaults write com.apple.dock springboard-page-duration -int 0

# Dock: position, auto-hide, Mission Control, and multi-monitor behavior
defaults write com.apple.dock orientation -string right
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock expose-group-apps -bool true # group windows by app in Mission Control (AeroSpace)
defaults write com.apple.spaces spans-displays -bool true  # displays span across monitors; disables "Displays have separate Spaces" (AeroSpace)
# Remove all pinned apps from the Dock
defaults write com.apple.dock persistent-apps -array
# Remove all pinned folders/files from the Dock
defaults delete com.apple.dock persistent-others 2>/dev/null || true

# Spotlight: disable default keyboard shortcuts (replaced by Raycast)
# Key 64 = cmd+space, Key 65 = cmd+option+space
# PlistBuddy edits specific keys without clobbering the rest of the dict
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:64:enabled false" ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:64:enabled bool false" ~/Library/Preferences/com.apple.symbolichotkeys.plist
/usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:65:enabled false" ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:65:enabled bool false" ~/Library/Preferences/com.apple.symbolichotkeys.plist
# Mission Control: disable ctrl+1 through ctrl+9 space-switching shortcuts
# Key IDs 118–126 correspond to ctrl+1 through ctrl+9
# Especially needed because ctrl+1/2/3 are relied on as in-app shortcuts in Bear and Zen browser
for key in 118 119 120 121 122 123 124 125 126; do
  /usr/libexec/PlistBuddy -c "Set :AppleSymbolicHotKeys:${key}:enabled false" ~/Library/Preferences/com.apple.symbolichotkeys.plist 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :AppleSymbolicHotKeys:${key}:enabled bool false" ~/Library/Preferences/com.apple.symbolichotkeys.plist
done

# Apply changes immediately (without this, a logout/reboot is required)
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

# Window tiling: cmd+ctrl+h = left, cmd+ctrl+l = right
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Tile Window to Left of Screen" "@^h"
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Tile Window to Right of Screen" "@^l"

# Restart affected services (once, at the end)
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

# Login Items
add_login_item() {
  local app_name="$1"
  local app_path="$2"

  existing=$(osascript -e 'tell application "System Events" to get the name of every login item')

  if echo "$existing" | grep -q "$app_name"; then
    echo "  $app_name already in Login Items, skipping"
  else
    osascript -e "tell application \"System Events\" to make login item at end with properties {name: \"$app_name\", path: \"$app_path\", hidden: false}"
    echo "  Added $app_name to Login Items"
  fi
}

add_login_item "Bear" "/Applications/Bear.app"
add_login_item "Raycast" "/Applications/Raycast.app"
add_login_item "1Password" "/Applications/1Password.app"

echo "Done! Some settings require a logout or reboot to take effect."
