#!/bin/zsh



export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.dotfiles/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"


export MISE_GITHUB_TOKEN=$(gh auth token)

# Shell integrations (mise/starship/fzf/zoxide) are initialized near the end of
# this file, after all PATH modifications, so mise-managed tools take precedence.

# Aliases

## kubernetes
alias k='kubectl'
alias kg="kubectl get"
alias kgp="kubectl get po"
alias kd="kubectl describe"
alias kl="kubectl logs"


## git
alias gitp='git push origin $(git branch --show-current)'

## laravel
alias art='php artisan'

alias lg='lazygit'
alias yz='yazi'

## scratch
function todaydir {
    local dir="$HOME/repos/control-room/scratch/days/$(date +%Y-%m-%d)"
    mkdir -p "$dir"
    echo "$dir"
}

# Functions

## Terminal
function title {
    echo -ne "\033]0;"$*"\007"
}

function rename-pane {
    if [[ -z "$1" ]]; then
        unset TMUX_PANE_NAME
        echo "Pane name cleared (back to auto)"
    else
        export TMUX_PANE_NAME="$*"
        printf '\033]2;%s\033\\' "$TMUX_PANE_NAME"
    fi
}

## tmux
function tmux-reset {
    tmux kill-pane -a
    tmux kill-window -a
    tmux rename-window '🖥️ nvim'
    tmux new-window -n '✏️ scratch'
    tmux new-window -n '🤖 clankers'
    tmux select-window -t 1
}

## Accessibility
function toggle-reduce-motion {
    local current=$(defaults read com.apple.universalaccess reduceMotion 2>/dev/null || echo "0")
    if [[ "$current" == "1" ]]; then
        defaults write com.apple.universalaccess reduceMotion -bool false
        echo "Reduce motion: OFF"
    else
        defaults write com.apple.universalaccess reduceMotion -bool true
        echo "Reduce motion: ON"
    fi
}

# export $TERM="xterm-256color"
export EDITOR="nvim"

# 1Password SSH agent
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

# Setting editor to nvim breaks emacs-style keybindings for regular shell input. Restore that:
bindkey -e

# Update tmux pane title with current command
if [[ -n "$TMUX" ]]; then
    precmd() {
        if [[ -n "$TMUX_PANE_NAME" ]]; then
            printf '\033]2;%s\033\\' "$TMUX_PANE_NAME"
        else
            echo -ne "\033]2;${PWD/#$HOME/~}\033\\"
        fi
    }
    preexec() { echo -ne "\033]2;$1\033\\" }
fi



export XDG_CONFIG_HOME="$HOME/.config"

# Herd Lite (PHP)
export PATH="$HOME/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="$HOME/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"

autoload -Uz compinit && compinit

# Local extras (not version controlled)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
# Shell integrations — must run AFTER all PATH modifications above (homebrew,
# herd-lite, jobrunner via .zshrc.local, flyctl) so mise's tool paths land first
# in PATH. Otherwise `mise doctor` warns that mise paths aren't first.
eval "$(~/.local/bin/mise activate zsh)"
eval "$(starship init zsh)"
source <(fzf --zsh)
eval "$(zoxide init zsh)"
