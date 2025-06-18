

# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME=""

autoload -U colors && colors

# Custom function for git status with Nerd Font icons
git_prompt_info_custom() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local branch=$(git branch --show-current 2>/dev/null)
        local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
        local behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)
        local git_status=""

        [[ $ahead -gt 0 ]] && git_status+=$'\uf062'"$ahead"
        [[ $behind -gt 0 ]] && git_status+=$'\uf063'"$behind"
        [[ -n $(git status --porcelain) ]] && git_status+=$'\uf444'

        echo "%{$fg[blue]%}"$'\ue0a0'" $branch%{$fg[red]%}$git_status%{$reset_color%}"
    fi
}

# Two-line prompt
PROMPT="%{$fg[cyan]%}"$'\uf007'" %n@%m%{$reset_color%} %{$fg[yellow]%}"$'\uf07b'" %~%{$reset_color%} \$(git_prompt_info_custom)
%{$fg[green]%}"$'\uf061'" %{$reset_color%}"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    docker
    node
    python
)

source $ZSH/oh-my-zsh.sh

# Custom exports
export EDITOR='nvim'
export VISUAL='nvim'

# Development paths
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/share/nvim/mason/bin:$PATH"

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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
    # WSL-specific configurations
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
fi
