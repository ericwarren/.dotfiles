# Enhanced .zshrc with True Color (24-bit) support
# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME=""

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# History settings
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY

# Custom exports
export EDITOR='nvim'
export VISUAL='nvim'
export DEFAULT_USER="$USER"

# Enable true color support for various applications
export TERM=xterm-256color
export COLORTERM=truecolor

# Development paths
export PATH="$HOME/.config/emacs/bin:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/.local/share/nvim/mason/bin:/usr/local/go/bin:$HOME/go/bin:$HOME/.dotnet/tools:$PATH"

# Doom Emacs configuration directory
export DOOMDIR="$HOME/.config/doom"

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Aliases
if [ -f ~/.zsh_aliases ]; then
    source ~/.zsh_aliases
fi

# Functions
if [ -f ~/.zsh_functions ]; then
    source ~/.zsh_functions
fi

# WSL specific settings
if grep -q Microsoft /proc/version 2>/dev/null; then
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
fi

# Initialize Starship prompt (MUST be at the end)
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# SSH agent configuration - works for both GUI (Kubuntu) and CLI (WSL)
# Prefer keychain if available, fallback to ksshaskpass for GUI, then manual ssh-agent
if command -v keychain &> /dev/null; then
    # Use keychain for persistent SSH agent (works in all environments)
    eval $(keychain --eval --quiet --agents ssh id_ed25519)
elif [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    # GUI environment (Kubuntu) - use ksshaskpass if available
    if command -v ksshaskpass &> /dev/null; then
        export SSH_ASKPASS=/usr/bin/ksshaskpass
        export SSH_ASKPASS_REQUIRE=prefer
    fi
    # Fallback: start ssh-agent if not running
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)" > /dev/null 2>&1
    fi
    # Auto-add SSH key if not already added
    if ! ssh-add -l &>/dev/null; then
        ssh-add ~/.ssh/id_ed25519 2>/dev/null
    fi
else
    # CLI environment fallback: start ssh-agent if not running
    if [ -z "$SSH_AUTH_SOCK" ]; then
        eval "$(ssh-agent -s)" > /dev/null 2>&1
    fi
    # Auto-add SSH key if not already added
    if ! ssh-add -l &>/dev/null; then
        ssh-add ~/.ssh/id_ed25519 2>/dev/null
    fi
fi

export GPG_TTY=$(tty)
