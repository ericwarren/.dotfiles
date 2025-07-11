#!/bin/bash
set -euo pipefail

# Minimal Arch Package Installation for WSL

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_header() {
    echo
    echo -e "${BLUE}=== $1 ===${NC}"
    echo
}

# Confirm installation
confirm_installation() {
    print_header "Minimal Arch Installation for WSL"
    print_status "Installing zsh, oh-my-zsh, starship, Neovim, Emacs with Doom, Node.js, and Claude Code"
    echo
    read -p "Continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Installation cancelled"
        exit 1
    fi
}

# Update system
update_system() {
    print_status "Updating system..."
    if sudo pacman -Syu --noconfirm; then
        print_success "System updated"
    else
        print_error "Failed to update system"
        exit 1
    fi
}

# Install GNU Stow
install_stow() {
    print_status "Installing GNU Stow for dotfile management..."
    if sudo pacman -S --noconfirm stow; then
        print_success "GNU Stow installed"
    else
        print_error "Failed to install GNU Stow"
        exit 1
    fi
}

# Install zsh and shell tools
install_zsh() {
    print_status "Installing zsh shell..."
    if sudo pacman -S --noconfirm zsh; then
        print_success "Zsh installed"
    else
        print_error "Failed to install zsh"
        exit 1
    fi
}

# Install oh-my-zsh
install_oh_my_zsh() {
    print_status "Installing oh-my-zsh..."
    
    # Check if oh-my-zsh is already installed
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh-my-zsh is already installed"
    else
        if sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            print_success "Oh-my-zsh installed"
        else
            print_error "Failed to install oh-my-zsh"
            exit 1
        fi
    fi

    # Install zsh plugins (skip if already present)
    print_status "Installing zsh plugins..."
    
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    else
        print_success "zsh-autosuggestions already installed"
    fi
    
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    else
        print_success "zsh-syntax-highlighting already installed"
    fi
    
    print_success "Zsh plugins setup complete"
}

# Install starship prompt
install_starship() {
    print_status "Installing starship prompt..."
    if curl -sS https://starship.rs/install.sh | sh -s -- --yes; then
        print_success "Starship installed"
    else
        print_error "Failed to install starship"
        exit 1
    fi
}

# Install fonts
install_fonts() {
    print_status "Installing fonts..."
    if sudo pacman -S --noconfirm ttf-cascadia-code-nerd noto-fonts-emoji noto-fonts-extra; then
        print_success "Cascadia Code Nerd Font and Noto fonts installed"
    else
        print_error "Failed to install fonts"
        exit 1
    fi
}

# Install Neovim
install_neovim() {
    print_status "Installing Neovim..."
    if sudo pacman -S --noconfirm neovim; then
        print_success "Neovim installed"
    else
        print_error "Failed to install Neovim"
        exit 1
    fi
}

# Install Emacs
install_emacs() {
    print_status "Installing Emacs..."
    if sudo pacman -S --noconfirm emacs; then
        print_success "Emacs installed"
    else
        print_error "Failed to install Emacs"
        exit 1
    fi
}

# Install Doom Emacs
install_doom_emacs() {
    print_status "Installing Doom Emacs..."

    # Install dependencies for Doom Emacs
    print_status "Installing Doom Emacs dependencies..."
    if sudo pacman -S --noconfirm git ripgrep fd; then
        print_success "Doom Emacs dependencies installed"
    else
        print_error "Failed to install Doom Emacs dependencies"
        exit 1
    fi

    # Remove existing Emacs config if present
    if [ -d "$HOME/.config/emacs" ] || [ -d "$HOME/.emacs.d" ]; then
        print_status "Backing up existing Emacs configuration..."
        [ -d "$HOME/.config/emacs" ] && mv "$HOME/.config/emacs" "$HOME/.config/emacs.bak.$(date +%Y%m%d%H%M%S)"
        [ -d "$HOME/.emacs.d" ] && mv "$HOME/.emacs.d" "$HOME/.emacs.d.bak.$(date +%Y%m%d%H%M%S)"
    fi

    # Clone Doom Emacs to ~/.config/emacs
    print_status "Cloning Doom Emacs repository..."
    if git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs; then
        print_success "Doom Emacs repository cloned"

        # Set DOOMDIR to use our stowed config location
        export DOOMDIR="$HOME/.config/doom"
        
        # Run Doom install script
        print_status "Running Doom install script (this may take a while)..."
        if DOOMDIR="$HOME/.config/doom" ~/.config/emacs/bin/doom install; then
            print_success "Doom Emacs installed successfully"

            # Add doom to PATH in current session
            export PATH="$HOME/.config/emacs/bin:$PATH"
            print_success "Doom binary added to PATH for current session"
        else
            print_error "Failed to run Doom install script"
            exit 1
        fi
    else
        print_error "Failed to clone Doom Emacs repository"
        exit 1
    fi
}

# Install NVM (Node Version Manager)
install_nvm() {
    print_status "Installing NVM (Node Version Manager)..."

    # Temporarily disable strict mode for NVM installation
    set +u

    # Download and install NVM
    if curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash; then
        print_success "NVM installed"

        # Source NVM to make it available in current session
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

        print_success "NVM sourced for current session"
    else
        print_error "Failed to install NVM"
        set -u  # Re-enable strict mode
        exit 1
    fi

    # Re-enable strict mode
    set -u
}

# Install Node.js using NVM
install_node() {
    print_status "Installing Node.js LTS using NVM..."

    # Temporarily disable strict mode for NVM usage
    set +u

    # Ensure NVM is available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install latest LTS version of Node.js
    if nvm install --lts; then
        print_success "Node.js LTS installed"

        # Use the LTS version
        nvm use --lts

        # Verify installation
        NODE_VERSION=$(node --version)
        NPM_VERSION=$(npm --version)
        print_success "Node.js version: $NODE_VERSION"
        print_success "NPM version: $NPM_VERSION"
    else
        print_error "Failed to install Node.js"
        set -u  # Re-enable strict mode
        exit 1
    fi

    # Re-enable strict mode
    set -u
}

# Install Claude Code
install_claude_code() {
    print_status "Installing Claude Code..."

    # Temporarily disable strict mode for NVM usage
    set +u

    # Ensure NVM is available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install Claude Code globally
    if npm install -g @anthropic-ai/claude-code; then
        print_success "Claude Code installed"

        # Verify installation
        if command -v claude &> /dev/null; then
            CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "installed")
            print_success "Claude Code version: $CLAUDE_VERSION"
        else
            print_success "Claude Code installed (restart terminal to use)"
        fi
    else
        print_error "Failed to install Claude Code"
        set -u  # Re-enable strict mode
        exit 1
    fi

    # Re-enable strict mode
    set -u
}

# Install system utilities
install_system_utilities() {
    print_status "Installing system utilities (SSH, git, base-devel)..."
    
    # Install build tools and SSH
    if sudo pacman -S --noconfirm --needed git base-devel openssh; then
        print_success "Development tools and SSH installed"
    else
        print_error "Failed to install development tools"
        exit 1
    fi

    # Install useful CLI tools
    if sudo pacman -S --noconfirm ripgrep fd bat eza fzf tmux htop ncdu ranger; then
        print_success "CLI utilities installed"
    else
        print_error "Failed to install CLI utilities"
        exit 1
    fi
}

# Verify NVM installations
verify_nvm_installations() {
    print_status "Verifying Node.js and Claude Code installations..."

    # Temporarily disable strict mode for NVM usage
    set +u

    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Check Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js is available: $NODE_VERSION"
    else
        print_error "Node.js not found in current session"
    fi

    # Check NPM
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        print_success "NPM is available: $NPM_VERSION"
    else
        print_error "NPM not found in current session"
    fi

    # Check Claude Code
    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "installed")
        print_success "Claude Code is available: $CLAUDE_VERSION"
    else
        print_error "Claude Code not found in current session"
    fi

    # Re-enable strict mode
    set -u
}


# Print completion message
print_completion() {
    print_header "Installation complete!"
    print_success "zsh, oh-my-zsh, starship, Neovim, Emacs with Doom, Node.js, and Claude Code are now installed."
    echo
    print_status "Next: Set up config files using stow"
    echo
    print_header "Important: Shell Setup"
    print_status "To set zsh as default shell: chsh -s \$(which zsh)"
    print_status "Then stow configs: stow zsh neovim emacs tmux"
    echo
    print_header "Important: Node.js and Claude Code Setup"
    print_status "To use Node.js and Claude Code, you need to source NVM:"
    echo "  source ~/.nvm/nvm.sh"
    echo "  source ~/.nvm/bash_completion"
    echo
    print_status "Or restart your terminal to automatically load NVM"
    print_status "Then verify with: node --version && claude --version"
    echo
    print_header "Important: Doom Emacs Setup"
    print_status "Add these to your shell config (.zshrc, .bashrc, etc.):"
    echo "  export PATH=\"\$HOME/.config/emacs/bin:\$PATH\""
    echo "  export DOOMDIR=\"\$HOME/.config/doom\""
    echo
    print_status "Your Doom configuration is tracked in ~/.config/doom/"
    print_status "After stowing emacs config, run: doom sync"
    print_status "This will install all Doom packages and compile configuration"
}

# Main function
main() {
    confirm_installation
    update_system
    install_system_utilities
    install_stow
    install_zsh
    install_oh_my_zsh
    install_starship
    install_fonts
    install_neovim
    install_emacs
    install_doom_emacs
    install_nvm
    install_node
    install_claude_code
    verify_nvm_installations
    print_completion
}

# Run main function
main "$@"