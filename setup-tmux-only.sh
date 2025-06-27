#!/bin/bash
# Minimal setup script for tmux + tmuxinator dependencies
# Only installs what's needed for the zellij → tmux transition

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}$1${NC}"
    echo "=============================================="
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

install_tmux_dependencies() {
    print_header "📦 Installing tmux Dependencies"
    
    echo "Updating package lists..."
    sudo apt update
    
    echo "Installing tmux and ruby (for tmuxinator)..."
    sudo apt install -y tmux ruby-full
    
    print_success "tmux and ruby installed"
}

install_tmuxinator() {
    print_header "🖥️ Installing tmuxinator"

    if command -v tmuxinator &> /dev/null; then
        print_success "tmuxinator already installed: $(tmuxinator version)"
        return
    fi

    echo "Installing tmuxinator via gem..."
    gem install tmuxinator

    print_success "tmuxinator installed: $(tmuxinator version)"
}

apply_tmux_dotfiles() {
    print_header "🔗 Applying tmux Dotfiles"
    
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [ ! -d "$script_dir/tmux" ]; then
        print_error "tmux dotfiles directory not found at $script_dir/tmux"
        return 1
    fi
    
    cd "$script_dir"
    echo "Applying tmux dotfiles with stow..."
    if stow -v tmux 2>/dev/null; then
        print_success "Applied tmux dotfiles"
    else
        print_warning "Failed to apply tmux dotfiles (may have conflicts)"
        echo "  You can resolve conflicts manually with: stow -v tmux"
    fi
}

verify_installation() {
    print_header "🔍 Verifying Installation"
    
    # Check tmux
    if command -v tmux &> /dev/null; then
        print_success "tmux: $(tmux -V)"
    else
        print_error "tmux not found"
    fi
    
    # Check tmuxinator
    if command -v tmuxinator &> /dev/null; then
        print_success "tmuxinator: $(tmuxinator version)"
    else
        print_error "tmuxinator not found"
    fi
    
    # Check if dotnet-tmux script exists
    if [ -x "$HOME/.local/bin/dotnet-tmux" ]; then
        print_success "dotnet-tmux launcher script installed"
    else
        print_warning "dotnet-tmux launcher script not found at ~/.local/bin/dotnet-tmux"
    fi
    
    # Check if tmuxinator config exists
    if [ -f "$HOME/.config/tmuxinator/dotnet-dev.yml" ]; then
        print_success "tmuxinator dotnet-dev config found"
    else
        print_warning "tmuxinator dotnet-dev config not found at ~/.config/tmuxinator/dotnet-dev.yml"
    fi
}

show_completion_message() {
    print_header "🎉 tmux Setup Complete!"
    
    echo -e "\n${GREEN}Your tmux + tmuxinator environment is ready!${NC}\n"
    
    echo "📋 What was installed:"
    echo "  • tmux $(tmux -V 2>/dev/null || echo 'latest')"
    echo "  • tmuxinator $(tmuxinator version 2>/dev/null || echo 'latest')"
    echo "  • tmux dotfiles applied with stow"
    echo "  • Neovim integration updated to use tmux instead of zellij"
    
    echo -e "\n📌 Next Steps:"
    echo "  1. Test the new setup: dotnet-tmux"
    echo "  2. Open Neovim in the tmux session and test keybindings:"
    echo "     • <leader>dw  - Start dotnet watch in tmux pane"
    echo "     • <F8>        - Quick watch run"
    echo "     • <leader>ds  - Stop watch"
    echo "  3. Navigate between panes with Ctrl+a + h/j/k/l"
    
    echo -e "\n💡 Usage:"
    echo "  • dotnet-tmux                    - Start default session"
    echo "  • dotnet-tmux my-project         - Start named session"
    echo "  • tmuxinator start dotnet-dev    - Direct tmuxinator usage"
    echo "  • tmux attach -t session-name    - Attach to existing session"
    
    echo -e "\n${GREEN}✨ No more timing issues with tmuxinator!${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 tmux + tmuxinator Setup${NC}"
    echo "=============================================="
    
    install_tmux_dependencies
    install_tmuxinator
    apply_tmux_dotfiles
    verify_installation
    show_completion_message
}

# Run main function
main "$@"