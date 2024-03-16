#!/bin/zsh


# Aliases

## kubernetes
alias k='kubectl'

## git
alias gitp='git push origin $(git branch --show-current)'

## laravel
alias art='php artisan'

# Functions

## Terminal
function title {
    echo -ne "\033]0;"$*"\007"
}
