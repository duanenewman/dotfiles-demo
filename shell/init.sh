# shellcheck shell=bash
# Shell setup shared by bash and zsh. install.sh adds one line to ~/.bashrc
# (and ~/.zshrc) that sources this file; everything else in those files is
# left to the machine.

# Interactive shells only.
case $- in *i*) ;; *) return 0 ;; esac

# bash knows this file's path as BASH_SOURCE; zsh puts it in $0.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"

# The repo's bin/ on PATH: new scripts work after a `git pull`, no reinstall.
case ":${PATH}:" in
  *":${DOTFILES_DIR}/bin:"*) ;;
  *) export PATH="${DOTFILES_DIR}/bin:${PATH}" ;;
esac

export EDITOR="${EDITOR:-vim}"
DOTFILES_WHERE="$(where-am-i)"
export DOTFILES_WHERE

# shellcheck source=SCRIPTDIR/aliases.sh
. "${DOTFILES_DIR}/shell/aliases.sh"
if [ -n "${BASH_VERSION:-}" ]; then
  # shellcheck source=SCRIPTDIR/prompt.bash
  . "${DOTFILES_DIR}/shell/prompt.bash"
fi

# Machine-specific or secret settings live outside the repo.
# shellcheck disable=SC1091
[ -f "${HOME}/.shell.local" ] && . "${HOME}/.shell.local"
