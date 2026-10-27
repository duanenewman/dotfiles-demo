---
name: worktree-shells
description: Add a tmux window of shells for a git worktree — a window named after the worktree with two shells (split top/bottom) sitting in its root folder. Use when the user asks to add/open worktree shells, a tmux window, or terminals for one or more worktrees.
argument-hint: "<worktree name, branch or path> [...]"
allowed-tools: Bash(tmux-worktree-window.sh:*), Bash(git worktree list:*)
---

Open tmux worktree shells for:

  $ARGUMENTS

1. Resolve each requested worktree to its root path with
   `git worktree list --porcelain` (run from the current repo). Match the
   request against, in order: the worktree folder's name (Claude worktrees
   live in `.claude/worktrees/<name>`), its branch, then its path. "This
   worktree" means the one you are working in. If a request matches no
   worktree or several, list the worktrees and ask instead of guessing. Do
   not create worktrees — only open shells for existing ones.

2. For each worktree, run:

       tmux-worktree-window.sh <worktree-root-path>

   The script names the window after the worktree's folder, starts both
   shells in its root, and leaves an existing window of the same name alone.
   Pass a second argument only if the user asked for a different window name.
   It lives in the dotfiles repo's `bin/`; if it is not on PATH, tell the
   user to run the dotfiles `install.sh` (or open a new shell).

3. Report the script's one-line output for each worktree. If it says you are
   not inside tmux, tell the user rather than trying to start tmux yourself.
