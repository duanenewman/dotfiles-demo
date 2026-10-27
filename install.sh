#!/usr/bin/env bash
# Dotfiles installer.
#
# VS Code Dev Containers and GitHub Codespaces clone your dotfiles repo into
# every new container and run the first of install.sh / bootstrap.sh /
# setup.sh they find. On any other machine (Linux, macOS, WSL) clone the repo
# and run this yourself.
#
# Rules this script follows:
#   - Link, don't copy: edits in the repo are live everywhere, and `git diff`
#     shows what changed.
#   - Include, don't replace: ~/.bashrc and ~/.gitconfig belong to the machine
#     (the base image, VS Code's copied git identity). We add one line to each
#     that pulls our config in, and leave the rest alone.
#   - Idempotent: running it twice is the same as running it once.
#   - Best effort: a missing package is a warning, never a failed container.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG="# dotfiles-demo"

# Symlink $1 at $2, backing up a real (non-link) file once so nothing is lost.
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "${dst}")"
  if [ -e "${dst}" ] && [ ! -L "${dst}" ]; then
    mv "${dst}" "${dst}.pre-dotfiles.bak"
    echo "  backed up ${dst} -> ${dst}.pre-dotfiles.bak"
  fi
  ln -sfn "${src}" "${dst}"
  echo "  linked ${dst}"
}

# Make $2 the only line tagged with $TAG in rc file $1. Rewriting (not
# appending) keeps re-runs idempotent and fixes the path if the clone moves.
set_tagged_line() {
  local rc="$1" line="$2" tmp
  touch "${rc}"
  tmp="$(mktemp)"
  grep -vF "${TAG}" "${rc}" >"${tmp}" || true
  printf '%s  %s\n' "${line}" "${TAG}" >>"${tmp}"
  # Write through cat so a symlinked rc file stays a symlink.
  cat "${tmp}" >"${rc}"
  rm -f "${tmp}"
  echo "  hooked ${rc}"
}

# Run as root directly or via sudo; fail quietly if neither is possible.
as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    sudo "$@"
  else
    return 1
  fi
}

# Install missing packages with whatever package manager this machine has.
ensure_packages() {
  local missing=() pkg
  for pkg in "$@"; do
    command -v "${pkg}" >/dev/null 2>&1 || missing+=("${pkg}")
  done
  if [ "${#missing[@]}" -eq 0 ]; then
    echo "  already installed: $*"
    return 0
  fi

  echo "  installing: ${missing[*]}"
  if command -v apt-get >/dev/null 2>&1; then
    as_root apt-get update -qq &&
      as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${missing[@]}"
  elif command -v apk >/dev/null 2>&1; then
    as_root apk add --no-cache "${missing[@]}"
  elif command -v dnf >/dev/null 2>&1; then
    as_root dnf install -y "${missing[@]}"
  elif command -v brew >/dev/null 2>&1; then
    brew install "${missing[@]}"
  else
    false
  fi >/dev/null || echo "  WARNING: could not install ${missing[*]}; carrying on." >&2
}

echo "dotfiles: installing from ${DOTFILES_DIR} ($("${DOTFILES_DIR}/bin/where-am-i"))"

echo "Linking config files:"
link "${DOTFILES_DIR}/tmux/tmux.conf" "${HOME}/.tmux.conf"
link "${DOTFILES_DIR}/editorconfig" "${HOME}/.editorconfig"

echo "Linking Claude Code skills:"
# One link per skill, so skills installed some other way coexist in
# ~/.claude/skills.
for skill_dir in "${DOTFILES_DIR}"/claude/skills/*/; do
  [ -d "${skill_dir}" ] || continue
  skill_dir="${skill_dir%/}"
  link "${skill_dir}" "${HOME}/.claude/skills/$(basename "${skill_dir}")"
done

echo "Hooking shell startup:"
init_line="[ -f '${DOTFILES_DIR}/shell/init.sh' ] && . '${DOTFILES_DIR}/shell/init.sh'"
set_tagged_line "${HOME}/.bashrc" "${init_line}"
if [ -f "${HOME}/.zshrc" ] || command -v zsh >/dev/null 2>&1; then
  set_tagged_line "${HOME}/.zshrc" "${init_line}"
fi

echo "Including git config:"
if command -v git >/dev/null 2>&1; then
  # --fixed-value: match the path literally; replace any old copy, add once.
  git config --global --unset-all --fixed-value include.path \
    "${DOTFILES_DIR}/git/gitconfig" 2>/dev/null || true
  git config --global --add include.path "${DOTFILES_DIR}/git/gitconfig"
  echo "  ~/.gitconfig includes ${DOTFILES_DIR}/git/gitconfig"
else
  echo "  git not found; skipping"
fi

if [ -z "${DOTFILES_SKIP_PACKAGES:-}" ]; then
  echo "Packages:"
  ensure_packages tmux jq tree
fi

echo "Done. Open a new shell (or: source ~/.bashrc)."
