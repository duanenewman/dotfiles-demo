#!/usr/bin/env bash
# Tests for install.sh. Each test runs the installer against a throwaway
# $HOME, so your real dotfiles are never touched. Needs bash and git.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

check() {
  local desc="$1"
  shift
  if "$@"; then
    PASS=$((PASS + 1))
    echo "  ok    ${desc}"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL  ${desc}"
  fi
}

fresh_home() {
  HOME="$(mktemp -d)"
  export HOME
  export DOTFILES_SKIP_PACKAGES=1
  unset GIT_CONFIG_GLOBAL
}

install() { "${REPO}/install.sh" >/dev/null; }

echo "fresh install"
fresh_home
check "installer succeeds" install
check "tmux.conf is a link into the repo" [ "$(readlink "${HOME}/.tmux.conf")" = "${REPO}/tmux/tmux.conf" ]
check "editorconfig is a link into the repo" [ "$(readlink "${HOME}/.editorconfig")" = "${REPO}/editorconfig" ]
check "bashrc sources init.sh" grep -qF "${REPO}/shell/init.sh" "${HOME}/.bashrc"
check "gitconfig includes the repo's gitconfig" \
  bash -c "git config --global --get-all include.path | grep -qxF '${REPO}/git/gitconfig'"
check "git aliases resolve" [ "$(git config --global --includes alias.st)" = "status -sb" ]
check "interactive shell gets aliases and bin/" \
  bash -ic 'alias gs >/dev/null && type mkcd >/dev/null && command -v where-am-i >/dev/null' 2>/dev/null

echo "re-running is a no-op"
install
install
check "one hook line in bashrc" [ "$(grep -cF '# dotfiles-demo' "${HOME}/.bashrc")" -eq 1 ]
check "one include in gitconfig" \
  [ "$(git config --global --get-all include.path | grep -cxF "${REPO}/git/gitconfig")" -eq 1 ]

echo "existing config is kept, not clobbered"
fresh_home
printf 'export KEEP_ME=1\n' >"${HOME}/.bashrc"
printf 'set -g mouse off\n' >"${HOME}/.tmux.conf"
git config --global user.name "Host Identity"
install
check "existing bashrc lines survive" grep -qxF 'export KEEP_ME=1' "${HOME}/.bashrc"
check "real tmux.conf backed up" grep -qF 'mouse off' "${HOME}/.tmux.conf.pre-dotfiles.bak"
check "git identity survives" [ "$(git config --global user.name)" = "Host Identity" ]

echo "local overrides"
printf '[alias]\n\tst = status\n' >"${HOME}/.gitconfig.local"
printf 'alias gs=MINE\n' >"${HOME}/.shell.local"
check ".gitconfig.local wins over the repo" [ "$(git config --global --includes alias.st)" = "status" ]
check ".shell.local wins over the repo" \
  bash -ic 'alias gs | grep -qF MINE' 2>/dev/null

echo
echo "${PASS} passed, ${FAIL} failed"
[ "${FAIL}" -eq 0 ]
