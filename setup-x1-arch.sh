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

# Install LightDM display manager
install_lightdm() {
    print_status "Installing LightDM display manager..."
    
    # Install LightDM with GTK greeter
    if sudo pacman -S --noconfirm lightdm lightdm-gtk-greeter; then
        print_success "LightDM and GTK greeter installed"
        
        # Create Hyprland session file
        print_status "Creating Hyprland session file..."
        sudo mkdir -p /usr/share/wayland-sessions/
        sudo tee /usr/share/wayland-sessions/hyprland.desktop > /dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Comment=Hyprland compositor
Exec=Hyprland
Type=Application
EOF
        print_success "Hyprland session file created"
        
        # Enable LightDM service
        if sudo systemctl enable lightdm; then
            print_success "LightDM service enabled"
        else
            print_error "Failed to enable LightDM service"
            exit 1
        fi
    else
        print_error "Failed to install LightDM"
        exit 1
    fi
}

# Install Hyprland ecosystem components
install_hyprland_ecosystem() {
    print_status "Installing Hyprland ecosystem components..."
    
    # Install core Hyprland ecosystem
    if sudo pacman -S --noconfirm hyprlock hypridle hyprpicker waybar; then
        print_success "Core Hyprland ecosystem installed"
    else
        print_error "Failed to install Hyprland ecosystem"
        exit 1
    fi
    
    # Install additional utilities
    if sudo pacman -S --noconfirm rofi mako swww brightnessctl; then
        print_success "Additional utilities installed"
    else
        print_error "Failed to install additional utilities"
        exit 1
    fi
}

# Install system utilities
install_system_utilities() {
    print_status "Installing system utilities (SSH, TLP power management)..."
    
    # Install SSH utilities
    if sudo pacman -S --noconfirm openssh; then
        print_success "OpenSSH installed"
    else
        print_error "Failed to install OpenSSH"
        exit 1
    fi
    
    # Install TLP for power management and clipboard utilities
    if sudo pacman -S --noconfirm tlp tlp-rdw powertop wl-clipboard; then
        print_success "TLP power management and clipboard utilities installed"
        
        # Enable TLP service
        if sudo systemctl enable tlp; then
            print_success "TLP service enabled"
        else
            print_error "Failed to enable TLP service"
            exit 1
        fi
    else
        print_error "Failed to install TLP"
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
    print_success "Hyprland, foot, Google Chrome, Node.js, and Claude Code are now installed."
    echo
    print_status "To start Hyprland, type 'Hyprland' in the TTY"
    print_status "Next: Set up config files using stow"
    echo
    print_header "Important: Node.js and Claude Code Setup"
    print_status "To use Node.js and Claude Code, you need to source NVM:"
    echo "  source ~/.nvm/nvm.sh"
    echo "  source ~/.nvm/bash_completion"
    echo
    print_status "Or restart your terminal to automatically load NVM"
    print_status "Then verify with: node --version && claude --version"
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
    install_lightdm
    install_hyprland_ecosystem
    install_system_utilities
    install_nvm
    install_node
    install_claude_code
    verify_nvm_installations
    print_completion
}

# Run main function
main "$@"