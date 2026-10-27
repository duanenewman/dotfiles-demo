# dotfiles-demo

A small, real dotfiles repo, built for the talk **Have Dotfiles, Will Travel:
Portable Developer Environments**. It works as-is, and it's meant to be
forked: change the aliases to yours and point your machines at it.

One `git clone` + `install.sh` gives any Linux, macOS, WSL machine or dev
container the same prompt, aliases, git config, tmux and editor defaults.
`install.ps1` does the same for native Windows.

## What's here

| Path | Ends up as | What it is |
| --- | --- | --- |
| `shell/init.sh` | sourced by `~/.bashrc`, `~/.zshrc` | Entry point: puts `bin/` on `PATH`, loads aliases and prompt, then `~/.shell.local`. |
| `shell/aliases.sh` | (via init.sh) | `ll`, `gs`, `gl`, `mkcd`, `groot`, `t` (tmux). |
| `shell/prompt.bash` | (via init.sh) | `[devcontainer] ~/src/app (main) $` with a color per environment. |
| `git/gitconfig` | `[include]`d by `~/.gitconfig` | Sensible defaults and aliases (`git lg`, `git st`, `git amend`...). No `[user]`. |
| `tmux/tmux.conf` | `~/.tmux.conf` (link) | Mouse, truecolor, big scrollback, vi copy mode. |
| `editorconfig` | `~/.editorconfig` (link) | LF, UTF-8, final newline, 2-space indent everywhere. |
| `bin/` | on `PATH` | `dotfiles` (`status` / `update`), `where-am-i`. |
| `powershell/profile.ps1` | dot-sourced by `$PROFILE` | The same aliases on native Windows. |
| `install.sh` / `install.ps1` | — | The installers. |
| `tests/test-install.sh` | — | Runs the installer against a throwaway `$HOME`. |
| `.devcontainer/` | — | A container for working on this repo. |
| `demo/sample-project/` | — | A plain project used in the live demo. |
| `docs/demo-script.md` | — | Run-of-show for the talk. |

## The four rules the installer follows

1. **Link, don't copy.** `~/.tmux.conf` is a symlink into the repo, so an edit
   is live right away and `git diff` shows it.
2. **Include, don't replace.** `~/.bashrc` and `~/.gitconfig` belong to the
   machine: the base image wrote one, and VS Code copied your git identity
   into the other. The installer adds *one tagged line* to each and leaves
   the rest alone.
3. **Idempotent.** Run it twice, get the same result. Re-running is how you
   update.
4. **Best effort.** A package that won't install is a warning. A dotfiles
   script that fails can leave you with a half-set-up container.

Anything machine-specific or secret goes in files the repo never sees:
`~/.shell.local`, `~/.gitconfig.local` (e.g. your work email), and
`~/.profile.local.ps1` on Windows. They load last, so they win.

## Use it with VS Code Dev Containers

Fork this repo, then in your **user** settings (not a project's):

```jsonc
"dotfiles.repository": "<you>/dotfiles-demo",   // or a full git URL
"dotfiles.targetPath": "~/dotfiles",             // where it's cloned
"dotfiles.installCommand": "install.sh"          // optional; found automatically
```

Each **new** container clones the repo and runs `install.sh`. Existing
containers won't change until you rebuild them, or until you run
`dotfiles update` inside one.

The same settings exist for the dev container CLI:

```bash
devcontainer up --workspace-folder . \
  --dotfiles-repository https://github.com/<you>/dotfiles-demo \
  --dotfiles-install-command install.sh
```

**GitHub Codespaces:** github.com → Settings → Codespaces → *Automatically
install dotfiles*, then pick this repo. Codespaces only uses dotfiles hosted
on GitHub.

## Use it anywhere else

Linux, macOS, WSL:

```bash
git clone https://github.com/<you>/dotfiles-demo ~/dotfiles
~/dotfiles/install.sh
```

Native Windows (PowerShell 5.1 or 7):

```powershell
git clone https://github.com/<you>/dotfiles-demo $HOME\dotfiles
& $HOME\dotfiles\install.ps1
```

Turn on Developer Mode so it can make symlinks; without it, files are copied
and you re-run the installer after pulling. In WSL, use `install.sh`. WSL is
Linux.

Keep the clone where it is, because the links point into it. To update:
`dotfiles update` (pull + re-run the installer).

## Hacking on it

```bash
tests/test-install.sh     # runs install.sh against a temp $HOME; needs bash + git
shellcheck -x install.sh bin/* shell/* tests/*.sh
```

Set `DOTFILES_SKIP_PACKAGES=1` to skip the package-install step.

Line endings are pinned to LF in `.gitattributes`. A shell script checked out
with CRLF on Windows fails inside Linux with `bad interpreter: /bin/bash^M`.
If you commit from Windows, set the executable bit too:
`git update-index --chmod=+x bin/<file>`.
