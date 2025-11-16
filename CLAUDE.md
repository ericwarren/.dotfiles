# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository using GNU Stow for symlink management. Each application configuration is stored in its own directory that mirrors the home directory structure (XDG Base Directory spec).

## Key Commands

### Stow Operations
```bash
# Install configurations (from ~/.dotfiles directory)
stow <package>              # Install single package
stow git zsh neovim tmux    # Install multiple packages
stow -v <package>           # Verbose mode to debug conflicts
stow -R <package>           # Restow (remove and recreate symlinks)
stow -D <package>           # Delete/uninstall symlinks
stow -nv <package>          # Dry run to preview changes

# Common package combinations
stow git zsh neovim tmux scripts claude    # Core development setup
stow alacritty qutebrowser                 # GUI applications
```

### Setup Scripts
- `setup-WSL-ubuntu.sh` - Ubuntu 22.04/24.04 setup for WSL
- `setup-X1-fedora.sh` - Fedora 40+ setup for Lenovo X1 Carbon

Both scripts install:
- Development toolchains (.NET, Go, Node.js via nvm, Python)
- Shell environment (zsh, Oh My Zsh, Starship prompt)
- CLI tools (fzf, ripgrep, eza, bat, jq, htop)
- Text editors (Neovim with plugins)
- Cloud CLIs (Azure CLI, GitHub CLI)
- Claude Code CLI
- Tmux Plugin Manager (TPM)

### Git Worktree + Tmux Development Workflow

Custom scripts in `scripts/.local/bin/` that integrate git worktrees with tmux sessions:

```bash
wtree <branch> [base]       # Create worktree + tmux session with Claude Code
wtree-ls                    # List all worktrees and tmux sessions
wtree-attach <branch>       # Attach to existing worktree session
wtree-rm <branch>           # Remove worktree and kill tmux session
```

**Workflow example:**
```bash
wtree feature-auth          # Creates: ../worktrees/feature-auth/ + tmux session
# Left pane: terminal, Right pane: Claude Code auto-started
wtree-ls                    # View all active worktrees
wtree-attach feature-auth   # Reattach to session
wtree-rm feature-auth       # Clean up when done
```

### Tmux Key Bindings

Prefix: `Ctrl+Space`

```bash
# Pane management
Ctrl+Space |        # Split vertical
Ctrl+Space -        # Split horizontal
Ctrl+Space h/j/k/l  # Navigate panes (vim-style)
Ctrl+Space H/J/K/L  # Resize panes
Ctrl+Space q        # Show pane numbers

# Session management
Ctrl+Space d        # Detach session
Ctrl+Space r        # Reload config

# Window navigation
Ctrl+Left/Right     # Previous/next window
```

## Architecture

### Directory Structure
```
~/.dotfiles/
├── git/            # Git configuration (.gitconfig)
├── zsh/            # Zsh shell (.zshrc, aliases, functions)
├── neovim/         # Neovim configuration (init.lua, lua/)
├── tmux/           # Tmux configuration (.tmux.conf)
├── scripts/        # Custom utility scripts (wtree, etc.)
├── claude/         # Claude Code configuration
├── alacritty/      # Alacritty terminal emulator
├── qutebrowser/    # Qutebrowser web browser
├── emacs/          # Doom Emacs configuration
├── fontconfig/     # Font settings
├── tlp/            # Power management (laptop)
└── libinput-gestures/  # Touchpad gestures
```

### Configuration Patterns

**Shell Environment (zsh/.zshrc):**
- Oh My Zsh with plugins: git, zsh-autosuggestions, zsh-syntax-highlighting
- Starship prompt (initialized at end of .zshrc)
- NVM for Node.js version management
- SSH agent auto-start with key loading
- WSL-specific settings for DISPLAY

**Tmux (tmux/.tmux.conf):**
- Custom prefix: `Ctrl+Space` (not `Ctrl+B`)
- TPM plugins: tmux-sensible, vim-tmux-navigator, tokyo-night theme
- True color support (24-bit RGB)
- Cross-platform clipboard integration (macOS/Linux/WSL)
- Vi-mode copy/paste keybindings

**Git Configuration (git/.gitconfig):**
- Useful aliases: `s` (status), `lol` (pretty log), `up` (pull with rebase)
- Workflow aliases: `bclean` (cleanup merged branches), `bdone` (checkout + update + clean)
- Default branch: `main`

**Neovim (neovim/.config/nvim/):**
- Lua-based configuration (init.lua + lua/ modules)
- Package management via lazy.nvim
- Configuration managed via stow

## Development Notes

### Adding New Configurations
1. Create directory matching application name (e.g., `sway/` for Sway WM)
2. Mirror home directory structure inside (e.g., `sway/.config/sway/config`)
3. Test with `stow -nv <package>` (dry run) to check for conflicts
4. Apply with `stow <package>`
5. Commit changes to git

### Common Issues
- **Stow conflicts**: Use `stow -v <package>` to identify conflicting files
- **Tmux plugins not loading**: Run `Ctrl+Space I` (capital I) to install TPM plugins
- **Zsh plugins missing**: Install via Oh My Zsh custom plugins directory
- **Shell environment not loading**: Ensure shell is changed to zsh with `chsh -s $(which zsh)`

### Cross-Platform Considerations
- Setup scripts handle OS-specific package managers (apt/dnf)
- Tmux config auto-detects clipboard tool (pbcopy/xclip/clip.exe)
- WSL-specific settings in .zshrc (DISPLAY variable)
- Stow works consistently across Linux distributions

### MCP Servers
Repository includes `.mcp.json` configuring multiple MCP servers for enhanced Claude Code functionality:
- **microsoft_docs_mcp**: Microsoft/Azure documentation search
- **context7**: Library documentation lookup
