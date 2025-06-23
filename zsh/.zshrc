# Enhanced .zshrc with True Color (24-bit) support
# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# Enable true color support
export COLORTERM=truecolor

autoload -U colors && colors

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    docker
    node
    python
    dotnet
    rust
)

source $ZSH/oh-my-zsh.sh

# Custom exports
export EDITOR='nvim'
export VISUAL='nvim'
export DEFAULT_USER="$USER"

# Enable true color support for various applications
export TERM=xterm-256color
export COLORTERM=truecolor

# Development paths
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

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
