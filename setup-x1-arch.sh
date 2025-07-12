#!/bin/bash
set -euo pipefail

# Minimal Arch Package Installation - Only Hyprland + Alacritty

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
    print_header "X1 Carbon Gen 9 Arch Installation"
    print_status "Installing Hyprland, WezTerm, Alacritty, zsh, oh-my-zsh, starship, Neovim, Emacs with Doom,"
    print_status "Google Chrome, Node.js, Claude Code, minicom, and X1 Carbon specific software:"
    print_status "  - Fingerprint reader support (fprintd)"
    print_status "  - ThinkPad battery management"
    print_status "  - Bluetooth support"
    print_status "  - Intel graphics tools"
    print_status "  - Firmware update support (fwupd)"
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

# Install WezTerm nightly
install_wezterm() {
    print_status "Installing WezTerm nightly from AUR..."
    
    # Install WezTerm nightly using yay
    print_status "Installing WezTerm nightly (this may take a while)..."
    if yay -S --noconfirm wezterm-git; then
        print_success "WezTerm nightly installed successfully"
    else
        print_error "Failed to install WezTerm nightly"
        exit 1
    fi
}

# Install Alacritty
install_alacritty() {
    print_status "Installing Alacritty terminal emulator..."
    if sudo pacman -S --noconfirm alacritty; then
        print_success "Alacritty installed"
    else
        print_error "Failed to install Alacritty"
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

# Install Google Chrome
install_chrome() {
    print_status "Installing Google Chrome..."
    
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
    if sudo pacman -S --noconfirm rofi mako swww brightnessctl jq rofimoji wl-clipboard; then
        print_success "Additional utilities installed"
    else
        print_error "Failed to install additional utilities"
        exit 1
    fi
}

# Configure PAM for hyprlock
configure_hyprlock_pam() {
    print_status "Configuring PAM for hyprlock..."
    
    # Create simplified PAM configuration for hyprlock
    sudo tee /etc/pam.d/hyprlock > /dev/null <<'EOF'
#%PAM-1.0
auth required pam_unix.so
account required pam_unix.so
EOF
    
    if [ $? -eq 0 ]; then
        print_success "PAM configuration for hyprlock created"
    else
        print_error "Failed to create PAM configuration for hyprlock"
        exit 1
    fi
}

# Install yay AUR helper
install_yay() {
    print_status "Installing yay AUR helper..."
    
    # Check if yay is already installed
    if command -v yay &> /dev/null; then
        print_success "yay is already installed"
        return 0
    fi
    
    # Install dependencies for building yay
    if sudo pacman -S --noconfirm --needed git base-devel; then
        # Clone and build yay
        local yay_dir="/tmp/yay-build"
        rm -rf "$yay_dir"
        
        if git clone https://aur.archlinux.org/yay.git "$yay_dir"; then
            cd "$yay_dir"
            if makepkg -si --noconfirm; then
                print_success "yay installed successfully"
                cd -
                rm -rf "$yay_dir"
            else
                print_error "Failed to build yay"
                exit 1
            fi
        else
            print_error "Failed to clone yay repository"
            exit 1
        fi
    else
        print_error "Failed to install build dependencies"
        exit 1
    fi
}

# Install system utilities
install_system_utilities() {
    print_status "Installing system utilities (SSH, TLP power management, AUR helper, minicom)..."
    
    # Install yay first
    install_yay

    # Install SSH utilities and minicom
    if sudo pacman -S --noconfirm openssh minicom; then
        print_success "OpenSSH and minicom installed"
    else
        print_error "Failed to install OpenSSH and minicom"
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

# Install X1 Carbon specific software
install_x1_carbon_specific() {
    print_header "Installing X1 Carbon Gen 9 Specific Software"
    
    # Fingerprint reader support
    print_status "Installing fingerprint reader support..."
    if sudo pacman -S --noconfirm fprintd imagemagick; then
        print_success "Fingerprint reader support installed"
    else
        print_error "Failed to install fingerprint reader support"
        exit 1
    fi
    
    # ThinkPad-specific tools
    print_status "Installing ThinkPad-specific tools..."
    if sudo pacman -S --noconfirm s-tui stress; then
        print_success "CPU monitoring tools installed"
    else
        print_error "Failed to install CPU monitoring tools"
        exit 1
    fi
    
    # Install tp-battery-mode from AUR
    print_status "Installing ThinkPad battery management from AUR..."
    if yay -S --noconfirm tp-battery-mode; then
        print_success "ThinkPad battery management installed"
    else
        print_error "Failed to install ThinkPad battery management"
        exit 1
    fi
    
    # Bluetooth support
    print_status "Installing Bluetooth support..."
    if sudo pacman -S --noconfirm bluez bluez-utils blueman; then
        print_success "Bluetooth support installed"
        
        # Enable bluetooth service
        if sudo systemctl enable bluetooth; then
            print_success "Bluetooth service enabled"
        else
            print_error "Failed to enable bluetooth service"
            exit 1
        fi
    else
        print_error "Failed to install Bluetooth support"
        exit 1
    fi
    
    # Webcam and audio utilities
    print_status "Installing webcam and audio utilities..."
    if sudo pacman -S --noconfirm v4l-utils guvcview pavucontrol; then
        print_success "Webcam and audio utilities installed"
    else
        print_error "Failed to install webcam and audio utilities"
        exit 1
    fi
    
    # Touchpad gestures
    print_status "Installing touchpad gesture support from AUR..."
    # Both libinput-gestures and libinput-gestures-qt are in AUR
    if yay -S --noconfirm libinput-gestures libinput-gestures-qt; then
        print_success "libinput-gestures and libinput-gestures-qt installed"
        
        # Add user to input group for gesture permissions
        print_status "Adding user to input group for touchpad gesture access..."
        if sudo gpasswd -a "$USER" input; then
            print_success "User added to input group (requires logout/login to take effect)"
        else
            print_error "Failed to add user to input group"
        fi
    else
        print_error "Failed to install touchpad gesture support"
        exit 1
    fi
    
    # Intel graphics tools
    print_status "Installing Intel graphics tools..."
    if sudo pacman -S --noconfirm intel-gpu-tools vulkan-intel; then
        print_success "Intel graphics tools installed"
    else
        print_error "Failed to install Intel graphics tools"
        exit 1
    fi
    
    # Firmware update support
    print_status "Installing firmware update support..."
    if sudo pacman -S --noconfirm fwupd; then
        print_success "fwupd installed"
        
        # Enable firmware update service
        if sudo systemctl enable fwupd; then
            print_success "Firmware update service enabled"
        else
            print_error "Failed to enable firmware update service"
            exit 1
        fi
    else
        print_error "Failed to install fwupd"
        exit 1
    fi
}

# Print completion message
print_completion() {
    print_header "Installation complete!"
    print_success "All software has been successfully installed including X1 Carbon specific tools."
    echo
    print_status "Installed software includes:"
    print_status "  - Hyprland, WezTerm, Alacritty"
    print_status "  - Zsh with oh-my-zsh and starship"
    print_status "  - Neovim and Emacs with Doom"
    print_status "  - Google Chrome, Node.js, Claude Code"
    print_status "  - Minicom and SSH utilities"
    print_status "  - X1 Carbon tools: fingerprint reader, battery management, bluetooth"
    echo
    print_status "To start Hyprland, type 'Hyprland' in the TTY"
    print_status "Next: Set up config files using stow"
    echo
    print_header "Important: Touchpad Gestures"
    print_status "You've been added to the 'input' group for touchpad gestures"
    print_status "You MUST logout and login again for this to take effect"
    print_status "After relogging, stow and start libinput-gestures:"
    print_status "  stow libinput-gestures"
    print_status "  libinput-gestures-setup start"
    print_status "  libinput-gestures-setup autostart"
    echo
    print_header "Important: Shell Setup"
    print_status "To set zsh as default shell: chsh -s \$(which zsh)"
    print_status "Then stow configs: stow zsh neovim emacs hyprland alacritty"
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
    echo
    print_header "X1 Carbon Specific Setup"
    print_status "Fingerprint setup: sudo fprintd-enroll"
    print_status "Battery thresholds: sudo tp-battery-mode -s 60 80"
    print_status "Firmware updates: sudo fwupdmgr refresh && sudo fwupdmgr update"
}

# Main function
main() {
    confirm_installation
    update_system
    install_system_utilities  # Install this early to get yay for AUR packages
    install_hyprland
    install_wezterm
    install_alacritty
    install_stow
    install_zsh
    install_oh_my_zsh
    install_starship
    install_fonts
    install_neovim
    install_emacs
    install_doom_emacs
    install_chrome
    install_lightdm
    install_hyprland_ecosystem
    configure_hyprlock_pam
    install_x1_carbon_specific
    install_nvm
    install_node
    install_claude_code
    verify_nvm_installations
    print_completion
}

# Run main function
main "$@"
