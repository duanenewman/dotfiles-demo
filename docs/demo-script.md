# Demo run-of-show

Target 20 minutes, with room to stretch to 30. The demos take about 8 of
those. Everything marked **(stretch)** can be cut on the day.

## Before the talk

- [ ] Fork/push this repo to GitHub as `<you>/dotfiles-demo` (public is
      easiest; Codespaces needs it on GitHub).
- [ ] VS Code **user** settings: `dotfiles.repository` **removed** for now.
      Keep the snippet below in a scratch file, ready to paste.
- [ ] Pre-pull the images so the rebuild takes seconds, not minutes:
      `docker pull mcr.microsoft.com/devcontainers/base:ubuntu`
- [ ] Open `demo/sample-project` in a container **once without dotfiles**, so
      demo 1 starts on the "before" state.
- [ ] A WSL terminal ready (or a second machine) for demo 3.
- [ ] Terminal font size up. Turn off notifications.
- [ ] Fallback: a screen recording of demos 1 and 2, in case of bad Wi-Fi.

```jsonc
"dotfiles.repository": "<you>/dotfiles-demo",
"dotfiles.targetPath": "~/dotfiles",
"dotfiles.installCommand": "install.sh"
```

## Demo 1: same container, before and after (about 4 min)

In the sample-project container, **without** dotfiles:

```bash
ll                 # command not found
git lg             # not a git command
cat ~/.tmux.conf   # no such file
```

The prompt is the image's default. *"This is every new container, every time."*

1. Paste the three settings into user settings.
2. Command Palette → **Dev Containers: Rebuild Container**.
3. Open a new terminal:

```bash
# prompt now reads [devcontainer] ...
ll
gs
git lg
dotfiles status    # what got linked, from where
ls -la ~ | grep -- '->'
git config --global --list --show-origin | grep include
```

Point out that the `[user]` name and email are still there. VS Code copied
them from the host, and the installer included its config instead of
replacing the file.

## Demo 2: change it once, get it everywhere (about 3 min) (stretch)

In the **dotfiles-demo** container (or any machine with the repo):

```bash
cd "$(dotfiles cd)"
echo "alias weather='curl -s wttr.in/?format=3'" >> shell/aliases.sh
git commit -am "Add weather alias" && git push
```

Then in the sample-project container:

```bash
dotfiles update    # git pull --ff-only + install.sh
exec bash
weather
```

*"Rebuilding the container would have done the same. A new container gets
it for free."*

## Demo 3: not a container (about 2 min)

In WSL, macOS or a fresh VM:

```bash
git clone https://github.com/<you>/dotfiles-demo ~/dotfiles
~/dotfiles/install.sh
exec bash          # prompt shows [wsl]
where-am-i
```

On Windows, show `install.ps1` briefly, then `gs` in PowerShell.

## Demo 4: a local override (about 1 min) (stretch)

```bash
printf '[user]\n\temail = me@work.example\n' > ~/.gitconfig.local
git config user.email
```

*"Work email on the work laptop. It never goes into the repo."*

## If something breaks

- Rebuild is slow: talk through the "how it runs" slide while it builds.
- Clone fails: check that the repo is public or that the host's git
  credentials can reach it. Run `install.sh` by hand from a local clone.
- The container came up with no dotfiles: look for the dotfiles step in the
  **Dev Containers** output channel (View → Output) and show it. That is the
  log you'd look at in real life anyway.
