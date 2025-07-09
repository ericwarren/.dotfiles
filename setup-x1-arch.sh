#!/bin/bash
set -euo pipefail

# Minimal Arch Package Installation - Only Hyprland + Foot

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
    print_header "Minimal Arch Installation"
    print_status "Installing Hyprland, foot, Google Chrome, Node.js, and Claude Code with essential dependencies"
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

# Install Hyprland
install_hyprland() {
    print_status "Installing Hyprland..."
    if sudo pacman -S --noconfirm hyprland; then
        print_success "Hyprland installed"
    else
        print_error "Failed to install Hyprland"
        exit 1
    fi
}

# Install foot
install_foot() {
    print_status "Installing foot..."
    if sudo pacman -S --noconfirm foot; then
        print_success "Foot installed"
    else
        print_error "Failed to install foot"
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

# Install Cascadia Code Nerd Font
install_cascadia_font() {
    print_status "Installing Cascadia Code Nerd Font..."
    if sudo pacman -S --noconfirm ttf-cascadia-code-nerd; then
        print_success "Cascadia Code Nerd Font installed"
    else
        print_error "Failed to install Cascadia Code Nerd Font"
        exit 1
    fi
}

# Install Google Chrome
install_chrome() {
    print_status "Installing Google Chrome..."
    
    # Check if yay is installed, if not install it
    if ! command -v yay &> /dev/null; then
        print_status "Installing yay AUR helper..."
        if ! sudo pacman -S --noconfirm --needed base-devel git; then
            print_error "Failed to install base-devel and git"
            exit 1
        fi
        
        # Install yay
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ~
        rm -rf /tmp/yay
        print_success "Yay installed"
    fi
    
    # Install Google Chrome using yay
    if yay -S --noconfirm google-chrome; then
        print_success "Google Chrome installed"
    else
        print_error "Failed to install Google Chrome"
        exit 1
    fi
}

# Install NVM (Node Version Manager)
install_nvm() {
    print_status "Installing NVM (Node Version Manager)..."
    
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
        exit 1
    fi
}

# Install Node.js using NVM
install_node() {
    print_status "Installing Node.js LTS using NVM..."
    
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
        exit 1
    fi
}

# Install Claude Code
install_claude_code() {
    print_status "Installing Claude Code..."
    
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
            print_success "Claude Code installed (may need to restart terminal)"
        fi
    else
        print_error "Failed to install Claude Code"
        exit 1
    fi
}


# Print completion message
print_completion() {
    print_header "Installation complete!"
    print_success "Hyprland, foot, Google Chrome, Node.js, and Claude Code are now installed."
    echo
    print_status "To start Hyprland, type 'Hyprland' in the TTY"
    print_status "Next: Set up config files using stow"
}

# Main function
main() {
    confirm_installation
    update_system
    install_hyprland
    install_foot
    install_stow
    install_cascadia_font
    install_chrome
    install_nvm
    install_node
    install_claude_code
    print_completion
}

# Run main function
main "$@"