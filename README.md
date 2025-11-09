# Dotfiles

Personal configuration files managed with GNU Stow.

## Quick Start

```bash
# Clone the repository
git clone https://github.com/ericwarren/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install configurations
stow git zsh neovim tmux
```

## Important: Personalize Your Configuration

Before using these dotfiles, you should personalize the following:

### Git Configuration
Edit `git/.gitconfig` to set your own name and email:
```bash
[user]
  name = Your Name
  email = your.email@example.com
```

## Available Configurations

- **git** - Git configuration and aliases
- **zsh** - Zsh shell with Oh My Zsh and Powerlevel10k
- **neovim** - Neovim editor with plugins
- **tmux** - Terminal multiplexer configuration
- **hyprland** - Wayland compositor (Arch Linux)
- **foot** - Terminal emulator for Wayland
- **qutebrowser** - Keyboard-driven web browser
- **emacs** - Emacs with Doom configuration
- **dropbox** - Dropbox utilities

## Installation

### Install Individual Packages
```bash
stow <package-name>
```

### Install Multiple Packages
```bash
stow git zsh neovim tmux qutebrowser
```

### Restow (update symlinks)
```bash
stow -R <package-name>
```

### Uninstall
```bash
stow -D <package-name>
```

## Setup Scripts

- `setup-WSL-ubuntu.sh` - Ubuntu 24.04 setup for WSL
- `setup-X1-fedora.sh` - Fedora setup for Lenovo X1 Carbon
- `setup-x1-arch.sh` - Arch Linux setup with Hyprland
- `setup-tmux-only.sh` - Minimal tmux-only setup

## Directory Structure

Each directory represents a stowable package that mirrors the home directory structure:
- Application configs follow XDG Base Directory spec (`.config/appname/`)
- Scripts go in `.local/bin/`
- System configs maintain their expected paths

## License

MIT
