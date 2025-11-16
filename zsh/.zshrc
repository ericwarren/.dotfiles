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

# Start ssh-agent if it's not already running
if ! pgrep ssh-agent > /dev/null 2>&1; then
    eval "$(ssh-agent -s)" > /dev/null
fi

# Add your SSH keys
ssh-add ~/.ssh/id_ed25519_personal 2>/dev/null
ssh-add ~/.ssh/id_ed25519_business 2>/dev/null
