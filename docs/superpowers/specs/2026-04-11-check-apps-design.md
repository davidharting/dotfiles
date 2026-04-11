---
title: check-apps.sh — App Installation Sanity Check
date: 2026-04-11
---

## Summary

A standalone script (`check-apps.sh`) that checks whether required macOS applications are installed and prints a clear status summary. Called automatically at the end of `bootstrap.sh` as a post-setup sanity check.

## Apps Checked

- Ghostty
- Raycast
- Zen Browser
- 1Password
- Superkey

## Behavior

### Detection

Each app is checked by looking for its `.app` bundle in `/Applications/` first, then `~/Applications/` as a fallback.

### Output

```
Checking required applications...

  ✓ Ghostty
  ✓ 1Password
  ✗ Raycast        (not installed)
  ✗ Zen Browser    (not installed)
  ✗ Superkey       (not installed)

3 app(s) missing. Install them manually to complete your setup.
```

If all apps are installed:

```
Checking required applications...

  ✓ Ghostty
  ✓ Raycast
  ✓ Zen Browser
  ✓ 1Password
  ✓ Superkey

All apps installed.
```

### Exit code

Always exits 0. Missing apps are advisory — they do not block bootstrap.

## Integration

`bootstrap.sh` calls `check-apps.sh` as its final step:

```bash
# Sanity check: verify required apps are installed
"$DOTFILES_DIR/check-apps.sh"
```

## Files Changed

- `check-apps.sh` — new file, repo root
- `bootstrap.sh` — add call to `check-apps.sh` at the end
