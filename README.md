# dotfiles
My configuration files, managed with [stow](https://www.gnu.org/software/stow/).

## Setup

```sh
./bootstrap.sh
```

Safe to re-run anytime. Installs Homebrew, mise, and Herd Lite (PHP) if missing, then runs `install.sh`. Also runs `mise install` and `check-apps.sh` to verify everything is in order.

Alternatively, run `install.sh` directly to skip the prerequisite checks.

## What `install.sh` does

Idempotent — safe to re-run anytime to sync changes. This will:

- Install/update Homebrew packages from `Brewfile`
- Stow all config packages to `~`
- Stow scripts to `~/.dotfiles/bin`
- Install yazi packages
- Apply macOS settings
