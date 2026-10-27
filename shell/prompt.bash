# shellcheck shell=bash
# A small bash prompt: [where] dir (branch) $
# The [where] tag makes it obvious which machine a terminal is on.

__dotfiles_branch() {
  local b
  b="$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)" || return 0
  [ -n "${b}" ] && printf ' (%s)' "${b}"
}

case "${DOTFILES_WHERE}" in
  devcontainer | codespace) __dotfiles_color='35' ;; # magenta
  wsl) __dotfiles_color='33' ;;                      # yellow
  *) __dotfiles_color='36' ;;                        # cyan
esac

PS1="\[\e[${__dotfiles_color}m\][${DOTFILES_WHERE}]\[\e[0m\] \[\e[1;34m\]\w\[\e[0m\]\[\e[32m\]\$(__dotfiles_branch)\[\e[0m\] \$ "
