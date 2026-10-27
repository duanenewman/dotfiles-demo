#!/usr/bin/env bash
# Tests for bin/tmux-worktree-window.sh. Needs tmux and git; never touches
# your own tmux server (each test uses a private socket directory).
#
#   tests/test-tmux-worktree-window.sh

# Checks are eval'd single-quoted strings, expanded when they run.
# shellcheck disable=SC2016,SC2034

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${REPO}/bin/tmux-worktree-window.sh"
command -v tmux >/dev/null 2>&1 || { echo "tmux is required" >&2; exit 1; }

WORK="$(mktemp -d)"
cleanup() {
  for dir in "${WORK}"/t*/sock; do
    TMUX_TMPDIR="${dir}" tmux kill-server 2>/dev/null || true
  done
  rm -rf "${WORK}"
}
trap cleanup EXIT

# A repo with a linked worktree, named like Claude's: .claude/worktrees/feat.x
git init -q "${WORK}/repo"
git -C "${WORK}/repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init
git -C "${WORK}/repo" worktree add -q "${WORK}/repo/.claude/worktrees/feat.x" -b feat.x
WT="$(cd "${WORK}/repo/.claude/worktrees/feat.x" && pwd -P)"

PASS=0
FAIL=0
n=0

# Fresh sandbox per test: private tmux server with session 'main', and the
# environment of a shell running in its first pane.
setup() {
  n=$((n + 1))
  T="${WORK}/t${n}"
  mkdir -p "${T}/sock"
  export TMUX_TMPDIR="${T}/sock"
  unset TMUX TMUX_PANE
  tmux new-session -d -s main
  # Created last, so it's the session tmux would pick without $TMUX_PANE.
  tmux new-session -d -s other
  TMUX="$(tmux display-message -p -t =main: '#{socket_path},0,#{session_id}')"
  TMUX_PANE="$(tmux display-message -p -t =main: '#{pane_id}')"
  export TMUX TMUX_PANE
}

check() {
  local name="$1"
  shift
  if "$@"; then
    PASS=$((PASS + 1))
    echo "ok   - ${name}"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL - ${name}"
  fi
}

windows() { tmux list-windows -t "=$1" -F '#W'; }
# "<pane count> <layout direction> <each pane's start dir>" of window $2 in $1.
describe() {
  local id
  id="$(tmux list-windows -t "=$1" -F '#{window_id} #W' | awk -v n="$2" '$2 == n { print $1 }')"
  echo "$(tmux list-panes -t "${id}" | wc -l) $(tmux list-panes -t "${id}" -F '#{pane_top}' | sort -u | wc -l)" \
    "$(tmux list-panes -t "${id}" -F '#{pane_current_path}' | sort -u)"
}

# Opens a 2-pane, top/bottom window named after the worktree, in its root.
setup
out="$(bash "${SCRIPT}" "${WT}/")"
check "window named after the worktree is added to the current session" \
  eval 'windows main | grep -qxF feat.x && ! windows other | grep -qxF feat.x'
check "two panes stacked top/bottom, both in the worktree root" \
  eval '[ "$(describe main feat.x)" = "2 2 ${WT}" ]'
check "window opens in the background" \
  eval '[ "$(tmux display-message -p -t =main: "#W")" != feat.x ]'
check "reports what it opened" eval '[[ "${out}" == *"feat.x"*"${WT}"* ]]'

# A subdirectory resolves to the worktree root; an explicit name wins.
setup
mkdir -p "${WT}/sub"
bash "${SCRIPT}" "${WT}/sub" custom >/dev/null
check "subdirectory resolves to root; explicit name is used" \
  eval '[ "$(describe main custom)" = "2 2 ${WT}" ]'

# Running twice leaves the existing window alone.
setup
bash "${SCRIPT}" "${WT}" >/dev/null
out="$(bash "${SCRIPT}" "${WT}")"
check "existing window is not duplicated" \
  eval '[ "$(windows main | grep -cxF feat.x)" = 1 ] && [[ "${out}" == *"already exists"* ]]'

# Errors.
setup
check "outside tmux is an error" \
  eval '! (unset TMUX TMUX_PANE; bash "${SCRIPT}" "${WT}") 2>/dev/null && ! windows main | grep -qxF feat.x'
check "non-git directory is an error" eval '! bash "${SCRIPT}" "${WORK}" 2>/dev/null'
check "missing directory is an error" eval '! bash "${SCRIPT}" "${WORK}/nope" 2>/dev/null'
check "no arguments is a usage error" eval '! bash "${SCRIPT}" 2>/dev/null'

echo "${PASS} passed, ${FAIL} failed"
[ "${FAIL}" -eq 0 ]
