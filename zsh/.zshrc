# Enhanced .zshrc with True Color (24-bit) support
# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME=""

# Enable true color support
export COLORTERM=truecolor

autoload -U colors && colors

# True color helper functions
# Usage: $(true_color_bg "255" "100" "50") for RGB background
# Usage: $(true_color_fg "255" "100" "50") for RGB foreground
true_color_bg() {
    echo "\033[48;2;${1};${2};${3}m"
}

true_color_fg() {
    echo "\033[38;2;${1};${2};${3}m"
}

color_reset() {
    echo "\033[0m"
}

# Enhanced git status function with true color Powerlevel10k-style features
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

    # True color definitions for git status
    local bg_color fg_color
    case $git_color in
        "green")
            # Clean git - nice green
            bg_color="$(true_color_bg "76" "175" "80")"   # Material Green
            fg_color="$(true_color_fg "255" "255" "255")" # White
            ;;
        "yellow")
            # Changes - orange/yellow
            bg_color="$(true_color_bg "255" "152" "0")"   # Material Orange
            fg_color="$(true_color_fg "0" "0" "0")"       # Black
            ;;
        "red")
            # Conflicts/issues - red
            bg_color="$(true_color_bg "244" "67" "54")"   # Material Red
            fg_color="$(true_color_fg "255" "255" "255")" # White
            ;;
        *)
            # Default - blue
            bg_color="$(true_color_bg "33" "150" "243")"  # Material Blue
            fg_color="$(true_color_fg "255" "255" "255")" # White
            ;;
    esac

    # Build final git segment with Git icon
    echo "%{${bg_color}${fg_color}%}  $branch$git_state$tracking$stash_indicator$status_indicators %{$(color_reset)%}"
}

# Enhanced directory segment with true colors
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
        # Not in git repo - show basename and parent
        if [[ "$current_dir" == "~" ]]; then
            display_dir="~"
        else
            local parent=$(dirname "$current_dir")
            local basename=$(basename "$current_dir")
            if [[ "$parent" == "/" ]] || [[ "$parent" == "~" ]]; then
                display_dir="$current_dir"
            else
                display_dir="$(basename "$parent")/$basename"
            fi
        fi
    fi

    # Directory segment - Material Blue
    local dir_bg="$(true_color_bg "63" "81" "181")"  # Material Indigo
    local dir_fg="$(true_color_fg "255" "255" "255")"
    echo "%{${dir_bg}${dir_fg}%}  $display_dir %{$(color_reset)%}"
}

# User segment with true colors
prompt_context() {
    local user_bg="$(true_color_bg "55" "71" "79")"    # Material Blue Grey 800
    local user_fg="$(true_color_fg "255" "255" "255")"
    echo "%{${user_bg}${user_fg}%}  %n@%m %{$(color_reset)%}"
}

# Python virtual environment indicator
prompt_virtualenv() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        local venv_name=$(basename "$VIRTUAL_ENV")
        local venv_bg="$(true_color_bg "76" "175" "80")"   # Material Green
        local venv_fg="$(true_color_fg "255" "255" "255")"
        echo "%{${venv_bg}${venv_fg}%}  $venv_name %{$(color_reset)%}"
    fi
}

# Node.js version indicator (only in Node projects)
prompt_node() {
    if [[ -f package.json ]] && command -v node > /dev/null 2>&1; then
        local node_version=$(node --version | sed 's/v//')
        local node_bg="$(true_color_bg "102" "187" "106")"  # Node green
        local node_fg="$(true_color_fg "255" "255" "255")"
        echo "%{${node_bg}${node_fg}%} ⬢ $node_version %{$(color_reset)%}"
    fi
}

# .NET version indicator (only in .NET projects)
prompt_dotnet() {
    if [[ -f *.csproj ]] || [[ -f *.sln ]] || [[ -f global.json ]] && command -v dotnet > /dev/null 2>&1; then
        local dotnet_version=$(dotnet --version 2>/dev/null)
        if [[ -n "$dotnet_version" ]]; then
            local dotnet_bg="$(true_color_bg "156" "39" "176")"  # .NET purple
            local dotnet_fg="$(true_color_fg "255" "255" "255")"
            echo "%{${dotnet_bg}${dotnet_fg}%}  $dotnet_version %{$(color_reset)%}"
        fi
    fi
}

# Rust version indicator (only in Rust projects)
prompt_rust() {
    if [[ -f Cargo.toml ]] && command -v rustc > /dev/null 2>&1; then
        local rust_version=$(rustc --version | awk '{print $2}')
        local rust_bg="$(true_color_bg "222" "165" "132")"  # Rust orange
        local rust_fg="$(true_color_fg "0" "0" "0")"
        echo "%{${rust_bg}${rust_fg}%}  $rust_version %{$(color_reset)%}"
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
            local time_color="$(true_color_fg "255" "193" "7")"  # Amber
            timer_show=" %{${time_color}%}⏱ ${elapsed}s%{$(color_reset)%}"
        else
            timer_show=""
        fi
        unset timer
    fi
}

# Powerline arrow separator
powerline_arrow() {
    local arrow_color="$(true_color_fg "255" "193" "7")"  # Golden arrow
    echo "%{${arrow_color}%}\uE0B0%{$(color_reset)%}"
}

# Clean prompt with powerline-style separator
PROMPT='$(prompt_context)$(prompt_dir_enhanced)$(prompt_virtualenv)$(prompt_node)$(prompt_dotnet)$(prompt_rust)$(git_prompt_info_enhanced)$(powerline_arrow)${timer_show}
%{$(true_color_fg "0" "188" "212")%}➜%{$(color_reset)%} '

# Right prompt with time and exit code using true colors
RPROMPT='%(?..%{$(true_color_fg "244" "67" "54")%}✗ %?%{$(color_reset)%} )%{$(true_color_fg "158" "158" "158")%}%T%{$(color_reset)%}'

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

# Test true color support function
test_true_color() {
    echo "Testing True Color Support:"
    echo "$(true_color_bg "255" "0" "0")$(true_color_fg "255" "255" "255") Red Background $(color_reset)"
    echo "$(true_color_bg "0" "255" "0")$(true_color_fg "0" "0" "0") Green Background $(color_reset)"
    echo "$(true_color_bg "0" "0" "255")$(true_color_fg "255" "255" "255") Blue Background $(color_reset)"
    echo "$(true_color_bg "123" "45" "67")$(true_color_fg "255" "255" "255") Custom RGB Background $(color_reset)"
}
