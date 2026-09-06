#!/usr/bin/env bash
# Sanity check: verify required macOS applications are installed.
# Exits 0 regardless — missing apps are advisory only.

check_app() {
  local name="$1"
  local bundle="$2"

  if [[ -d "/Applications/$bundle" || -d "$HOME/Applications/$bundle" ]]; then
    echo "  ✓ $name"
    return 0
  else
    echo "  ✗ $name  (not installed)"
    return 1
  fi
}

echo ""
echo "Checking required applications..."
echo ""

missing=0

check_app "Ghostty" "Ghostty.app" || ((missing++))
check_app "Raycast" "Raycast.app" || ((missing++))
check_app "Zen Browser" "Zen.app" || ((missing++))
check_app "1Password" "1Password.app" || ((missing++))

echo ""
if [[ $missing -eq 0 ]]; then
  echo "All apps installed."
else
  echo "$missing app(s) missing. Install them manually to complete your setup."
fi
echo ""
