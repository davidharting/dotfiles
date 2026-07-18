# dotfiles
My configuration files, managed with [stow](https://www.gnu.org/software/stow/).

## Setup

```sh
./bootstrap.sh
```

Safe to re-run anytime. Installs Homebrew, mise, and Herd Lite (PHP) if missing, then runs `install.sh`. Also runs `mise install` and `check-apps.sh` to verify everything is in order.

Alternatively, run `install.sh` directly to skip the prerequisite checks.

## Development

Install the pinned development tools and run the checks with mise:

```sh
mise install
mise run check
```

Use `mise run test` for the bashunit suite and `mise run format` to apply
`shfmt` formatting.

## What `install.sh` does

Idempotent — safe to re-run anytime to sync changes. This will:

- Install/update Homebrew packages from `Brewfile`
- Stow all config packages to `~`
- Link `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md` to `~/.agents/AGENTS.md`
- Stow scripts to `~/.dotfiles/bin`
- Install yazi packages
- Apply macOS settings

## Agent instructions

Edit `agents/.agents/AGENTS.md` to update shared user-level instructions for coding agents. `install.sh` stows it to `~/.agents/AGENTS.md` and symlinks `~/.codex/AGENTS.md` and `~/.claude/CLAUDE.md` there.
