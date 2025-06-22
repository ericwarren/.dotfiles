# Enhanced .zshrc with Powerlevel10k-style git status
# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME=""

autoload -U colors && colors

# Enhanced git status function with Powerlevel10k-style features
git_prompt_info_enhanced() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return
    fi

    local branch=$(git branch --show-current 2>/dev/null)
    local git_color="green"

    # If no branch name (detached HEAD), show commit hash
    if [[ -z "$branch" ]]; then
        branch="@$(git rev-parse --short HEAD 2>/dev/null)"
        git_color="yellow"
    fi

    # Check for various git states
    local git_state=""

    # Check if we're in a merge, rebase, etc.
    if [[ -f .git/MERGE_HEAD ]]; then
        git_state=" MERGE"
        git_color="red"
    elif [[ -d .git/rebase-merge ]] || [[ -d .git/rebase-apply ]]; then
        git_state=" REBASE"
        git_color="red"
    elif [[ -f .git/CHERRY_PICK_HEAD ]]; then
        git_state=" CHERRY-PICK"
        git_color="red"
    elif [[ -f .git/BISECT_LOG ]]; then
        git_state=" BISECT"
        git_color="red"
    fi

    # Count ahead/behind commits
    local upstream=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null)
    local ahead=0
    local behind=0

    if [[ -n "$upstream" ]]; then
        ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
        behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
    fi

    # Build ahead/behind indicators
    local tracking=""
    if [[ $ahead -gt 0 ]]; then
        tracking+=" ↑$ahead"
    fi
    if [[ $behind -gt 0 ]]; then
        tracking+=" ↓$behind"
    fi

    # Count stashes
    local stash_count=$(git stash list 2>/dev/null | wc -l)
    local stash_indicator=""
    if [[ $stash_count -gt 0 ]]; then
        stash_indicator=" *$stash_count"
    fi

    # Check working directory status
    local status_output=$(git status --porcelain=v1 2>/dev/null)
    local staged=0
    local modified=0
    local untracked=0
    local deleted=0
    local conflicts=0

    if [[ -n "$status_output" ]]; then
        while IFS= read -r line; do
            case "${line:0:2}" in
                "A "* | "M "* | "D "* | "R "* | "C "*) ((staged++)) ;;
                "??"*) ((untracked++)) ;;
                *"U"* | "AA"* | "DD"* | "AU"* | "UA"* | "DU"* | "UD"*) ((conflicts++)) ;;
                " M"* | " T"*) ((modified++)) ;;
                " D"*) ((deleted++)) ;;
            esac
        done <<< "$status_output"

        # If there are any changes, make it yellow/red
        if [[ $staged -gt 0 ]] || [[ $modified -gt 0 ]] || [[ $untracked -gt 0 ]] || [[ $deleted -gt 0 ]] || [[ $conflicts -gt 0 ]]; then
            git_color="yellow"
        fi

        if [[ $conflicts -gt 0 ]]; then
            git_color="red"
        fi
    fi

    # Build status indicators
    local status_indicators=""
    [[ $staged -gt 0 ]] && status_indicators+=" +$staged"
    [[ $modified -gt 0 ]] && status_indicators+=" ~$modified"
    [[ $deleted -gt 0 ]] && status_indicators+=" -$deleted"
    [[ $untracked -gt 0 ]] && status_indicators+=" ?$untracked"
    [[ $conflicts -gt 0 ]] && status_indicators+=" !$conflicts"

    # Check if working directory is clean
    if [[ -z "$status_output" ]] && [[ -z "$git_state" ]]; then
        status_indicators=" ✓"
        git_color="green"
    fi

    # Determine colors based on git status
    local bg_color fg_color
    case $git_color in
        "green")
            bg_color="%{$BG[28]%}"    # Dark green
            fg_color="%{$FG[255]%}"   # White
            ;;
        "yellow")
            bg_color="%{$BG[214]%}"   # Orange/yellow
            fg_color="%{$FG[16]%}"    # Black
            ;;
        "red")
            bg_color="%{$BG[196]%}"   # Bright red
            fg_color="%{$FG[255]%}"   # White
            ;;
        *)
            bg_color="%{$BG[68]%}"    # Blue fallback
            fg_color="%{$FG[255]%}"   # White
            ;;
    esac

    # Build final git segment
    echo "${bg_color}${fg_color}  $branch$git_state$tracking$stash_indicator$status_indicators %{$reset_color%}"
}

# Enhanced directory segment with git-aware shortening
prompt_dir_enhanced() {
    local current_dir="$PWD"
    local display_dir=""

    # Replace home directory with ~
    if [[ "$current_dir" == "$HOME"* ]]; then
        current_dir="~${current_dir#$HOME}"
    fi

    # If we're in a git repo, show path relative to git root
    if git rev-parse --git-dir > /dev/null 2>&1; then
        local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
        local git_basename=$(basename "$git_root")
        local relative_path=${PWD#$git_root}

        if [[ "$relative_path" == "$PWD" ]]; then
            # We're at git root
            display_dir="$git_basename"
        else
            # We're in a subdirectory
            display_dir="$git_basename$relative_path"
        fi
    else
        # Not in git repo - just show current directory without complex shortening
        display_dir="$current_dir"
    fi

    # Directory segment - better blue
    echo "%{$bg[blue]%}%{$fg[white]%}  $display_dir %{$reset_color%}"
}

# User segment
prompt_context() {
    echo "%{$bg[black]%}%{$fg[white]%}  %n@%m %{$reset_color%}"
}

# Python virtual environment indicator
prompt_virtualenv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_name=$(basename "$VIRTUAL_ENV")
        echo "%{$BG[37]%}%{$FG[16]%}  $venv_name %{$reset_color%}"
    fi
}

# Node.js version indicator (only in Node projects)
prompt_node() {
    if [[ -f package.json ]] && command -v node > /dev/null 2>&1; then
        local node_version=$(node --version | sed 's/v//')
        echo "%{$BG[34]%}%{$FG[255]%}  $node_version %{$reset_color%}"
    fi
}

# .NET version indicator (only in .NET projects)
prompt_dotnet() {
    if [[ -f *.csproj ]] || [[ -f *.sln ]] || [[ -f global.json ]] && command -v dotnet > /dev/null 2>&1; then
        local dotnet_version=$(dotnet --version 2>/dev/null)
        if [[ -n "$dotnet_version" ]]; then
            echo "%{$BG[99]%}%{$FG[255]%}  $dotnet_version %{$reset_color%}"
        fi
    fi
}

# Rust version indicator (only in Rust projects)
prompt_rust() {
    if [[ -f Cargo.toml ]] && command -v rustc > /dev/null 2>&1; then
        local rust_version=$(rustc --version | awk '{print $2}')
        echo "%{$BG[208]%}%{$FG[16]%}  $rust_version %{$reset_color%}"
    fi
}

# Command execution time (for long-running commands)
preexec() {
    timer=${timer:-$SECONDS}
}

precmd() {
    if [ $timer ]; then
        local elapsed=$((SECONDS - timer))
        if [ $elapsed -gt 3 ]; then
            timer_show=" %{$fg[yellow]%}${elapsed}s%{$reset_color%}"
        else
            timer_show=""
        fi
        unset timer
    fi
}

# Clean prompt with single chevron after git status
PROMPT='$(prompt_context)$(prompt_dir_enhanced)$(prompt_virtualenv)$(prompt_node)$(prompt_dotnet)$(prompt_rust)$(git_prompt_info_enhanced)%{$FG[214]%}'$'\uE0B0''%{$reset_color%}${timer_show}
%{$fg[cyan]%}➜ %{$reset_color%}'

# Right prompt with time and exit code
RPROMPT='%(?..%{$fg[red]%}✗ %?%{$reset_color%} )%{$fg[grey]%}%T%{$reset_color%}'

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

# Additional git aliases for the enhanced prompt
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gl='git pull'
alias ga='git add'
alias gc='git commit'
alias gca='git commit -a'
alias gcm='git commit -m'
alias gd='git diff'
alias gdc='git diff --cached'
