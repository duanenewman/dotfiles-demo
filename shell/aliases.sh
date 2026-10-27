# shellcheck shell=bash
# Aliases and small functions. Keep these boring and portable (bash + zsh).

alias ll='ls -alF'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'

alias gs='git status -sb'
alias gl='git lg -20'
alias gd='git diff'
alias gco='git checkout'

# Make a directory and cd into it.
mkcd() { mkdir -p "$1" && cd "$1" || return; }

# Jump to the root of the current git repo.
groot() { cd "$(git rev-parse --show-toplevel)" || return; }

# Start or attach to a tmux session (default "main").
t() { tmux new-session -A -s "${1:-main}"; }
