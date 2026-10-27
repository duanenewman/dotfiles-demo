#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Open a tmux window of worktree shells
#
# Adds a window to the current tmux session with two shells, split top and
# bottom, both started in the root of the given git worktree. The window is
# named after the worktree (its root folder's name) and opens in the
# background, so it doesn't pull focus from the window you're in.
#
# Usage:
#
#   tmux-worktree-window.sh <worktree-path> [window-name]
#
# Any path inside the worktree works. If the session already has a window
# with that name, nothing is created. Must run inside tmux: "current session"
# is the one $TMUX_PANE belongs to.
# =============================================================================

die() {
  echo "tmux-worktree-window: $*" >&2
  exit 1
}

{ [ $# -ge 1 ] && [ $# -le 2 ]; } || die "usage: tmux-worktree-window.sh <worktree-path> [window-name]"
command -v tmux >/dev/null 2>&1 || die "tmux is not installed (or not on PATH)."
[ -n "${TMUX:-}" ] || die "not running inside tmux."

[ -d "$1" ] || die "no such directory: $1"
dir="$(git -C "$1" rev-parse --show-toplevel 2>/dev/null)" ||
  die "not inside a git worktree: $1"
name="${2:-$(basename "${dir}")}"
[ -n "${name}" ] || die "window name is empty."

session="$(tmux display-message -p '#{session_id}')"

if tmux list-windows -t "${session}" -F '#{window_name}' | grep -qxF -- "${name}"; then
  echo "Window '${name}' already exists in session $(tmux display-message -p -t "${session}" '#S'); left as is."
  exit 0
fi

# Target by window id from here on: names containing '.' or ':' would be
# parsed as pane/session separators.
win="$(tmux new-window -d -P -F '#{window_id}' -t "${session}:" -n "${name}" -c "${dir}")"
tmux split-window -v -d -t "${win}" -c "${dir}"

echo "Opened window '${name}' in session $(tmux display-message -p -t "${session}" '#S'): 2 shells in ${dir}"
