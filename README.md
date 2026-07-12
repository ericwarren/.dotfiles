# Dotfiles

Personal configuration for a Kubuntu (KDE Plasma) development machine, managed
with GNU Stow. Focused on **Python, .NET/C#, and Rust** development.

## Quick Start

```bash
git clone git@github.com:ericwarren/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Full machine provisioning (Kubuntu / Lenovo X1 Carbon Gen 9):
./setup-X1-kubuntu.sh

# ...or just symlink configs with stow:
mkdir -p ~/.claude          # required before `stow claude` — see Gotchas
stow git zsh neovim tmux scripts claude alacritty emacs fontconfig
```

## Packages

| Package | What it is |
|---|---|
| `git` | Git config and aliases |
| `zsh` | Zsh + Oh My Zsh, Starship prompt, fnm, SSH agent |
| `neovim` | Neovim (lazy.nvim) |
| `tmux` | Tmux — prefix `Ctrl+Space`, TPM plugins |
| `scripts` | `wtree` git-worktree + tmux helpers (`~/.local/bin`) |
| `claude` | Claude Code: `settings.json`, `statusline.sh`, `skills/` |
| `alacritty` | Alacritty terminal |
| `emacs` | Doom Emacs config + `emacs --daemon` user service |
| `fontconfig` | `monospace` → Nerd Font mapping |
| `tlp` | Tuned TLP power profile (X1 Gen 9) — reference only, not auto-applied |

## Setup Scripts

- `setup-X1-kubuntu.sh` — **primary**, full Kubuntu provisioning
- `setup-WSL-ubuntu.sh` — WSL (secondary)
- `setup-X1-fedora.sh` — Fedora (secondary)

## Stow usage

```bash
stow <pkg>        # install (symlink into $HOME)
stow -R <pkg>     # restow after changes
stow -D <pkg>     # uninstall
stow -nv <pkg>    # dry run (preview / debug conflicts)
```

## Gotchas / Important notes

- **Personalize git identity** — `git/.gitconfig` sets name/email; change to yours.
- **Claude package & stow folding** — `~/.claude` also holds credentials, sessions,
  and history. Run `mkdir -p ~/.claude` **before** `stow claude` so stow links only
  the sub-paths (`settings.json`, `statusline.sh`, `skills/`) instead of turning the
  whole directory into a symlink into this repo. Do it **before** creating any local
  skills, or `~/.claude/skills` will conflict. Secrets/state are gitignored. See
  `claude/README.md`.
- **Node uses fnm, not nvm** — `.zshrc` evals `fnm env`; the setup installs fnm + Node LTS.
- **voxd (voice-to-text)** — needs a Python ≤3.13 venv (Ubuntu 26.04 ships 3.14, which
  voxd rejects; the setup creates a uv-managed 3.13 venv at `~/.local/share/voxd/.venv`).
  Also needs the `input` group for sudo-free `ydotool`. Run `voxd --setup` once after install.
- **keyd** — its config is `/etc/keyd/default.conf` (a system path, not stow-managed);
  the setup script writes it. Remaps CapsLock → Esc (tap) / Ctrl (hold).
- **Doom Emacs** — the setup clones the framework to `~/.config/emacs`, runs `doom install`,
  and enables the daemon (`systemctl --user enable --now emacs`). The `emacs` package
  provides the daemon unit and your private `~/.config/doom` config.
- **MCP servers are not stowable** — MCP config lives in `~/.claude.json` (machine-local,
  holds secrets), not a stowable file. Account-level MCP connectors (e.g. Microsoft Learn)
  sync via your Claude login, so they're available on every machine after `claude` auth —
  nothing to stow.
- **TLP is not applied automatically** — KDE's power-profiles-daemon handles power well
  out of the box; set the 80% battery charge limit in KDE System Settings if you want it.

## License

MIT
