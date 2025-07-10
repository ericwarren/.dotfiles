# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository using GNU Stow for symlink management. Each application configuration is stored in its own directory that mirrors the home directory structure.

## Key Commands

### Stow Operations
```bash
# Install configurations (from ~/.dotfiles directory)
stow <package>              # Install single package
stow git zsh neovim tmux    # Install multiple packages
stow -v <package>           # Verbose mode to debug conflicts
stow -R <package>           # Restow (remove and recreate symlinks)
stow -D <package>           # Delete/uninstall symlinks

# Common package combinations
stow git zsh neovim tmux qutebrowser  # Developer setup
stow hyprland foot                    # Hyprland desktop
```

### Setup Scripts
- `setup-x1-arch.sh` - Arch Linux setup for Lenovo X1 Carbon with Hyprland
- `setup.sh` - Ubuntu 24.04/Fedora 42 setup for WSL
- `setup-X1-fedora.sh` - Fedora setup for X1 Carbon
- `setup-tmux-only.sh` - Minimal tmux-only setup

### Hyprland Specific
```bash
hyprctl reload              # Reload Hyprland configuration
hyprctl monitors            # Check monitor configuration
```

## Architecture

### Directory Structure
Each directory represents a stowable package:
- Application configs follow XDG Base Directory spec (`.config/appname/`)
- Scripts go in `.local/bin/`
- System configs (like TLP) maintain their expected paths

### Configuration Patterns
- **Hyprland**: Main config at `hyprland/.config/hypr/hyprland.conf`
- **Media keys**: Configured in Hyprland config (XF86Audio*, XF86MonBrightness*, etc.)
- **Audio**: Uses pipewire with pulseaudio compatibility layer
- **Display management**: Custom display-toggle script for F7 key

### Current Branch Context
Feature branch `feature/hyprland-customization` focuses on Hyprland desktop environment setup.

## Development Notes

### Adding New Configurations
1. Create directory matching application name
2. Mirror home directory structure inside
3. Test with `stow -nv <package>` (dry run)
4. Commit changes before stowing

### Common Issues
- **Stow conflicts**: Use `-v` flag to identify conflicting files
- **Audio not working**: Run `install-audio.sh` to install pipewire stack
- **Display toggle needs jq**: Already added to `setup-x1-arch.sh`

### MCP Server
Repository includes `.claude.json` configuring the context7 MCP server for enhanced Claude Code functionality.