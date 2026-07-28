# herdr

Notes for moving from tmux + sesh to [herdr](https://herdr.dev), an
agent-aware terminal multiplexer. The recommended config lives in
`herdr/.config/herdr/config.toml`; this file explains the reasoning and,
more importantly, what does **not** carry over.

herdr runs fine inside tmux, so none of this has to happen at once.

## Install

Not in `mise/.config/mise/config.toml` yet, on purpose. Two options:

```sh
curl -fsSL https://herdr.dev/install.sh | sh   # upstream installer
mise use -g github:ogulcancelik/herdr@latest   # matches how hunk/abtop/pls are pinned
```

Verify the mise route resolves a release asset before committing it to the
tool list — a bad entry there breaks `bootstrap.sh` on a fresh machine. If
herdr ends up mise-managed, don't run `herdr update`; it self-replaces the
binary out from under mise. Use `mise upgrade` instead.

## The model

| tmux | herdr |
| --- | --- |
| server | session (`herdr session list/attach/stop`) |
| session | workspace |
| window | tab |
| pane | pane |
| `sesh` picker | built-in workspace navigation (`prefix+w`) |
| `choose-tree` | `goto` navigator, filterable by agent state |

Ids are positional and **compact when things close** (`1-1`, `1:2`). They are
not durable handles — re-read them from `herdr pane list` rather than caching.

## Keybindings

The config keeps the tmux spelling wherever herdr had a free key.

| action | tmux | herdr (configured) |
| --- | --- | --- |
| prefix | `ctrl+b` (ghostty `cmd+k`) | same, unchanged |
| split side by side | `prefix v` | `prefix v` |
| split stacked | `prefix h` | `prefix shift+h` or `prefix -` |
| kill pane | `prefix x` | `prefix x` |
| new window/tab | `prefix c` | `prefix c` |
| scrollback into `$EDITOR` | `prefix e` | `prefix e` |
| session/workspace picker | `prefix s` (sesh) | `prefix s` or `prefix w` |
| tree view | `prefix S` | `prefix G` or `prefix g` |
| switch window/tab 1-9 | `prefix 1..9` | `prefix 1..9` |
| detach | `prefix d` | `prefix q` |
| pane focus | `ctrl+h/j/k/l` | `prefix h/j/k/l` |

Three tmux binds have no herdr equivalent at all:

- `prefix /` — tmux-fuzzback. Gone. Closest replacement is `prefix e`, which
  dumps the scrollback into nvim, where `/` works.
- `prefix f` — `display-popup`. herdr has no popup layer.
- `prefix b` — `break-pane`. `prefix b` is the sidebar toggle in herdr.

`prefix r` also changes meaning: it was "reload config" in tmux, it is
"resize mode" in herdr. Reload moved to `prefix shift+r`. Harmless misfire —
`esc` exits resize mode — but it will happen for a week.

## What breaks and what to do about it

### 1. `sesh` has no direct replacement

Two separate things go away.

**Directory-to-session picking.** `sesh` merges tmux sessions, zoxide
history, configured entries, and an `fd` search into one fzf list. herdr's
`goto` navigator only fuzzy-searches panes and workspaces that already
exist — there is no directory picker. `herdr workspace create --cwd <dir>`
always creates. Attach-or-create, the job `scripts/tat` does today, becomes:

```sh
# rough shape of a herdr-flavored `tat`
target="$(pwd -P)"
existing="$(herdr workspace list | jq -r --arg p "$target" \
  '.result.workspaces[] | select(.cwd == $p) | .workspace_id' | head -1)"
if [ -n "$existing" ]; then
  exec herdr workspace focus "$existing"
fi
exec herdr workspace create --cwd "$target"
```

Verify the JSON shape against a live `herdr workspace list` before writing
this for real; `SKILL.md` documents the envelope but not every field.

**Declarative window layouts.** `sesh/.config/sesh/sesh.toml` gives every
`~/repos/**` session the same three windows (`✏️ scratch`, `🤖 clankers`,
`📦 etc`) plus a renamed root. herdr's config has no session-template
section — no `[[window]]`, no `startup_command`. The nearest thing is a
custom command keybinding that shells out to the socket API:

```toml
[[keys.command]]
key = "prefix+shift+i"
type = "shell"
command = "herdr-scaffold"   # a script that runs `herdr tab create --label ...` x3
```

`type = "shell"` runs detached in the background, which is right for a
scaffold script but wrong for anything with a UI. `type = "pane"` opens a
real pane, which is what you want if you ever wrap fzf this way.

### 2. `wtt` / worktrunk keeps working, but don't use herdr's worktrees

herdr has a built-in worktree feature on `prefix shift+g`. It checks out to
`<worktrees.directory>/<repo>/<branch-slug>` — default `~/.herdr/worktrees` —
with the branch slugged by lowercasing and replacing every non-alphanumeric
character with `-`. So `davidharting/foo` becomes `davidharting-foo`, and
nothing strips the `davidharting/` or `dh/` prefix the way the worktrunk
template does.

That contradicts both `worktrunk/.config/worktrunk/config.toml` and the
"place worktrees under `<repo>/.worktrees/<name>`" rule in
`agents/.agents/AGENTS.md`. The recommended config unbinds `new_worktree`
so it can't fire by accident.

`scripts/wtt` itself survives — only its `--execute tat` tail needs to point
at a herdr-aware attach script.

### 3. vim-tmux-navigator degrades gracefully, then bites once

`nvim/.config/nvim/lua/plugins/vim-tmux-navigator.lua` binds `ctrl+h/j/k/l`
to `TmuxNavigate*`, which shells out to `tmux select-pane`. Under herdr with
no tmux around, `$TMUX` is unset and the plugin falls back to plain `wincmd` —
so `ctrl+h/j/k/l` become ordinary nvim window navigation. That's fine.

The bite: **run herdr inside tmux and `$TMUX` is set again**, so those keys
move the *outer* tmux panes while you are looking at herdr panes. During any
side-by-side period, either drop the plugin or accept that.

This is also why the config leaves pane focus on `prefix+h/j/k/l` instead of
binding bare `ctrl+h/j/k/l` in herdr: herdr has no `is_vim` process check, so
a direct binding would swallow those keys before nvim ever saw them.

### 4. No plugins, no plugin manager

`tpack` and both plugins (`sainnhe/tmux-fzf`, `roosta/tmux-fuzzback`) have
nothing to migrate to — herdr has no plugin system. `[[keys.command]]` running
shell or pane commands is the entire extension surface.

`scripts/fzf-tmux` exists only because fuzzback needed it. Once tmux is gone
it is dead code, along with the `mise.toml` lint/format exclusions for it.

### 5. Copy mode is mouse-first

`mode-keys vi`, `v` to select, `y` to copy — none of that exists. herdr
selects with the mouse and copies via the platform clipboard or OSC 52.
There is no keyboard-driven copy mode and no scrollback search. If you copy
by keyboard often, this is the biggest daily regression.

The upside: OSC 52 means copy works over SSH without
`reattach-to-user-namespace`, which can come out of the Brewfile eventually.

### 6. No status bar to style

Everything in `.tmux.conf` from `status-position` through `status-right`
becomes nothing. herdr renders a sidebar instead, tunable only through
`sidebar_width` / `sidebar_min_width` / `sidebar_max_width` and `accent`.
The `#{s|/_worktrees/|/|;=34:session_name}` trick in `status-left` has no
equivalent — workspace labels come from the repo or folder name, or from
`prefix shift+w`.

### 7. Pane titles work differently

`.zshrc` sets pane titles two ways: the `rename-pane` function exports
`TMUX_PANE_NAME` and emits OSC 2, and the `precmd`/`preexec` hooks emit OSC 2
with the cwd or the running command. Both are gated on `[[ -n "$TMUX" ]]`, so
under herdr they simply stop firing.

herdr labels panes itself — agent name on the border (enabled in the config)
plus a manual label on `prefix shift+p`. If you want the zsh hooks back,
re-gate them on `[[ -n "$HERDR_ENV" ]]` and confirm herdr honors OSC 2 for
pane labels; that isn't documented.

`tmux-reset` in `.zshrc` becomes a `herdr tab`-based script or goes away.

### 8. herdr writes to its own config file

The settings screen, the onboarding flow, and `herdr config reset-keys` all
rewrite `~/.config/herdr/config.toml` in place with a plain `fs::write`,
which follows the stow symlink straight into this repo. Consequences:

- After the first run, expect an unstaged `onboarding = false` line. That's
  normal, and committing it is the right move.
- Theme and sound changes made in the settings UI land here as a diff.
  Convenient, but review before committing — the app rewrites keys, it does
  not preserve comments in the sections it touches.

### 9. Logs land in the config directory

herdr writes `herdr.log`, `herdr-client.log`, `herdr-server.log` and rotated
`.1`/`.2` siblings into `~/.config/herdr/`, not into a state directory. Since
`herdr/.config/herdr/` holds only one file, stow folds the whole directory
into a symlink and those logs appear inside this repo.

`.gitignore` covers them. To avoid it entirely, `mkdir -p ~/.config/herdr`
before the first `install.sh` — stow won't fold a directory that already
exists, and will link just the file.

(Session state does go somewhere sane: `~/.local/state/herdr/`.)

### 10. Persistence is a server, not a socket file

`herdr` starts or attaches to a background session server. `ctrl+b q`
detaches, agents keep running, `herdr server stop` kills it. Named sessions
(`herdr session attach work`) are separate servers sharing one config file —
they are *not* the replacement for tmux sessions. Workspaces are.

## What you actually gain

Worth being concrete, since the list above is all cost:

- Agent state in the sidebar — blocked / working / done / idle — for claude,
  codex, and pi, all three of which are already in `mise.toml`. The `🤖
  clankers` window pattern exists precisely because tmux can't show this.
- `delivery = "system"` toasts when a background agent goes blocked.
- Agents can drive the multiplexer over the socket API: split a pane, run
  tests in it, `herdr wait output ... --match ...`, read the result back.
  Worth adding to `agents/.agents/AGENTS.md` once you commit to the switch.
- `herdr --remote host` attaches through ssh with local keybindings.

## Suggested order

1. Install herdr, run it *inside* tmux, keep everything else as-is.
2. Live in it for a week for agent work only; leave normal shell work in tmux.
3. If it sticks: write the `tat` replacement, repoint `wtt --execute`, and
   decide about the scaffold script.
4. Only then retire `.tmux.conf`, `sesh.toml`, `scripts/fzf-tmux`, and
   `tpack`.
