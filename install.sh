#!/bin/bash

# WSL Ubuntu Development Environment Setup Script with Nix
# Installs: git, neovim, zsh, gnu stow using Nix package manager
# Expects to be run from ~/.dotfiles repository

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "This script should not be run as root"
   exit 1
fi

# Check if running in WSL
if ! grep -qi microsoft /proc/version; then
    log_error "This script is designed for WSL Ubuntu only"
    log_info "Detected system: $(uname -a)"
    exit 1
fi

log_info "Detected WSL Ubuntu environment"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXPECTED_DIR="$HOME/.dotfiles"

log_info "Script running from: $SCRIPT_DIR"

# Verify we're running from the expected location
if [[ "$SCRIPT_DIR" != "$EXPECTED_DIR" ]]; then
    log_warning "This script should be run from $EXPECTED_DIR"
    log_warning "Current location: $SCRIPT_DIR"
    log_info "Expected workflow:"
    log_info "  1. git clone <your-repo> ~/.dotfiles"
    log_info "  2. cd ~/.dotfiles && ./setup.sh"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Exiting. Please run from $EXPECTED_DIR"
        exit 1
    fi
fi

# Install Nix package manager if not already installed
install_nix() {
    if command -v nix &> /dev/null; then
        log_success "Nix is already installed"
        nix --version
        return 0
    fi
    
    log_info "Installing Nix package manager..."
    
    # Install Nix using the official installer
    sh <(curl -L https://nixos.org/nix/install) --daemon
    
    # Source the nix profile
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    
    # Add to current session
    export PATH="/nix/var/nix/profiles/default/bin:$PATH"
    
    if command -v nix &> /dev/null; then
        log_success "Nix installed successfully"
        nix --version
    else
        log_error "Nix installation failed"
        exit 1
    fi
}

# Install packages using Nix
install_nix_packages() {
    log_info "Installing development packages with Nix..."
    
    # Install packages
    nix-env -iA \
        nixpkgs.git \
        nixpkgs.neovim \
        nixpkgs.zsh \
        nixpkgs.stow \
        nixpkgs.curl \
        nixpkgs.wget \
        nixpkgs.unzip \
        nixpkgs.fontconfig
    
    log_success "Nix packages installed"
}

# Install Caskaydia Cove Nerd Font
install_caskaydia_font() {
    log_info "Installing Caskaydia Cove Nerd Font..."
    
    # Create fonts directory
    mkdir -p "$HOME/.local/share/fonts"
    
    # Download the font
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"
    TEMP_DIR="/tmp/caskaydia-font"
    
    # Create temp directory and download
    mkdir -p "$TEMP_DIR"
    curl -Lo "$TEMP_DIR/CascadiaCode.zip" "$FONT_URL"
    
    # Extract only the Caskaydia Cove variants
    unzip -j "$TEMP_DIR/CascadiaCode.zip" "*CaskaydiaCove*" -d "$HOME/.local/share/fonts/"
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
    # Refresh font cache
    if command -v fc-cache &> /dev/null; then
        fc-cache -f -v "$HOME/.local/share/fonts/"
        log_success "Caskaydia Cove Nerd Font installed and font cache updated"
    else
        log_success "Caskaydia Cove Nerd Font installed"
        log_warning "fc-cache not available, you may need to restart your terminal"
    fi
    
    # Show installed fonts
    log_info "Installed font files:"
    ls -la "$HOME/.local/share/fonts/"*CaskaydiaCove* 2>/dev/null || log_warning "No Caskaydia font files found"
}

# Configure Nix environment
configure_nix_env() {
    log_info "Configuring Nix environment..."
    
    # Create nix configuration directory
    mkdir -p "$HOME/.config/nix"
    
    # Enable flakes and new nix command
    cat > "$HOME/.config/nix/nix.conf" << 'EOF'
experimental-features = nix-command flakes
EOF
    
    # Add Nix to shell profiles if not already there
    NIX_PROFILE_SCRIPT="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    
    for shell_config in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$shell_config" ]] && ! grep -q "nix-daemon.sh" "$shell_config"; then
            echo "" >> "$shell_config"
            echo "# Nix package manager" >> "$shell_config"
            echo "if [[ -f $NIX_PROFILE_SCRIPT ]]; then" >> "$shell_config"
            echo "    source $NIX_PROFILE_SCRIPT" >> "$shell_config"
            echo "fi" >> "$shell_config"
            log_info "Added Nix to $(basename "$shell_config")"
        fi
    done
    
    log_success "Nix environment configured"
}

log_info "Starting WSL Ubuntu development environment setup with Nix..."

# Install Nix package manager
install_nix

# Configure Nix environment
configure_nix_env

# Install packages
install_nix_packages

# Install Oh My Zsh (optional but recommended)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
else
    log_warning "Oh My Zsh already installed, skipping..."
fi

# Install Caskaydia Cove Nerd Font
install_caskaydia_font

# Check for dotfiles packages in current location
DOTFILES_DIR="$SCRIPT_DIR"

# Look for dotfiles packages (directories that aren't common repo files)
EXCLUDE_DIRS=("\.git" "\.github" "docs" "scripts" "bin")
EXCLUDE_FILES=("setup\.sh" "README\.md" "LICENSE" "\.gitignore")

# Find potential dotfiles packages
PACKAGES=()
for item in "$DOTFILES_DIR"/*; do
    if [[ -d "$item" ]]; then
        basename_item=$(basename "$item")
        # Skip excluded directories
        skip=false
        for exclude in "${EXCLUDE_DIRS[@]}"; do
            if [[ "$basename_item" =~ $exclude ]]; then
                skip=true
                break
            fi
        done
        if [[ "$skip" == false ]]; then
            PACKAGES+=("$basename_item")
        fi
    fi
done

if [[ ${#PACKAGES[@]} -gt 0 ]]; then
    log_success "Found dotfiles packages: ${PACKAGES[*]}"
else
    log_warning "No dotfiles packages found in: $DOTFILES_DIR"
    log_info "Expected structure:"
    log_info "  ~/.dotfiles/"
    log_info "  ├── setup.sh (this script)"
    log_info "  ├── git/          # dotfiles package"
    log_info "  ├── zsh/          # dotfiles package" 
    log_info "  └── nvim/         # dotfiles package"
fi

# Create dotfiles management script
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/dotfiles" << EOF
#!/bin/bash
# Dotfiles management script using GNU Stow

DOTFILES_DIR="$DOTFILES_DIR"

case "\$1" in
    "install"|"stow")
        if [[ -z "\$2" ]]; then
            echo "Usage: dotfiles install <package>"
            echo "Available packages:"
            ls -1 "\$DOTFILES_DIR" 2>/dev/null | grep -v -E '(setup\.sh|README\.md|LICENSE|\.git)' || echo "No packages found in \$DOTFILES_DIR"
            exit 1
        fi
        cd "\$DOTFILES_DIR" && stow "\$2"
        echo "Installed dotfiles package: \$2"
        ;;
    "uninstall"|"unstow")
        if [[ -z "\$2" ]]; then
            echo "Usage: dotfiles uninstall <package>"
            exit 1
        fi
        cd "\$DOTFILES_DIR" && stow -D "\$2"
        echo "Uninstalled dotfiles package: \$2"
        ;;
    "restow")
        if [[ -z "\$2" ]]; then
            echo "Usage: dotfiles restow <package>"
            exit 1
        fi
        cd "\$DOTFILES_DIR" && stow -R "\$2"
        echo "Restowed dotfiles package: \$2"
        ;;
    "install-all")
        if [[ -d "\$DOTFILES_DIR" ]]; then
            echo "Installing all available packages..."
            cd "\$DOTFILES_DIR"
            for package in */; do
                if [[ -d "\$package" ]]; then
                    package_name="\${package%/}"
                    # Skip non-dotfiles directories
                    if [[ ! "\$package_name" =~ ^(\.git|\.github|docs|scripts|bin)$ ]] && [[ ! -f "\$package_name" ]]; then
                        echo "Installing: \$package_name"
                        stow "\$package_name"
                    fi
                fi
            done
            echo "All packages installed"
        else
            echo "Dotfiles directory not found: \$DOTFILES_DIR"
        fi
        ;;
    "list")
        echo "Available dotfiles packages:"
        ls -1 "\$DOTFILES_DIR" 2>/dev/null | grep -v -E '(setup\.sh|README\.md|LICENSE|\.git)' || echo "No packages found in \$DOTFILES_DIR"
        ;;
    "status")
        echo "Dotfiles directory: \$DOTFILES_DIR"
        echo "Available packages:"
        ls -1 "\$DOTFILES_DIR" | grep -v -E '(setup\.sh|README\.md|LICENSE|\.git)' 2>/dev/null || echo "No packages found"
        echo ""
        echo "Current symlinks in home directory:"
        find "\$HOME" -maxdepth 3 -type l -exec ls -la {} \; 2>/dev/null | grep "\$DOTFILES_DIR" || echo "No dotfile symlinks found"
        echo ""
        echo "Nix packages:"
        nix-env -q || echo "No Nix packages installed"
        ;;
    "nix-update")
        echo "Updating Nix packages..."
        nix-channel --update
        nix-env -u
        echo "Nix packages updated"
        ;;
    "edit")
        if [[ -z "\$2" ]]; then
            echo "Usage: dotfiles edit <package>"
            echo "Available packages:"
            ls -1 "\$DOTFILES_DIR" 2>/dev/null | grep -v -E '(setup\.sh|README\.md|LICENSE|\.git)' || echo "No packages found in \$DOTFILES_DIR"
            exit 1
        fi
        cd "\$DOTFILES_DIR/\$2"
        \${EDITOR:-nvim} .
        ;;
    "cd")
        echo "cd \$DOTFILES_DIR"
        ;;
    *)
        echo "Dotfiles management script (Nix-powered)"
        echo "Usage: dotfiles <command> [package]"
        echo ""
        echo "Commands:"
        echo "  install/stow <package>    - Install dotfiles package"
        echo "  uninstall/unstow <package> - Uninstall dotfiles package"
        echo "  restow <package>          - Reinstall dotfiles package"
        echo "  install-all               - Install all available packages"
        echo "  list                      - List available packages"
        echo "  status                    - Show status, symlinks, and Nix packages"
        echo "  nix-update                - Update all Nix packages"
        echo "  edit <package>            - Edit package files with \\\$EDITOR"
        echo "  cd                        - Print command to cd to dotfiles dir"
        echo ""
        echo "Dotfiles location: \$DOTFILES_DIR"
        ;;
esac
EOF

# Make the dotfiles script executable and ensure it's in PATH
chmod +x "$HOME/.local/bin/dotfiles"

# Add ~/.local/bin to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
fi

# Change default shell to zsh
log_info "Changing default shell to zsh..."
ZSH_PATH=$(which zsh)
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    # Add zsh to /etc/shells if not present
    if ! grep -q "$ZSH_PATH" /etc/shells; then
        echo "$ZSH_PATH" | sudo tee -a /etc/shells
    fi
    chsh -s "$ZSH_PATH"
    log_success "Default shell changed to zsh (will take effect on next login)"
else
    log_warning "Zsh is already the default shell"
fi

# Install useful zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    log_info "Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    log_info "Installing zsh-syntax-highlighting plugin..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Summary
log_success "WSL Ubuntu development environment setup with Nix complete!"
echo ""
echo "Installed with Nix:"
echo "  - Git: $(git --version 2>/dev/null || echo 'Not found in PATH')"
echo "  - Neovim: $(nvim --version 2>/dev/null | head -n1 || echo 'Not found in PATH')"
echo "  - Zsh: $(zsh --version 2>/dev/null || echo 'Not found in PATH')"
echo "  - GNU Stow: $(stow --version 2>/dev/null | head -n1 || echo 'Not found in PATH')"
echo "  - Oh My Zsh with plugins"
echo "  - Caskaydia Cove Nerd Font"
echo ""
echo "Dotfiles setup:"
echo "  - Repository location: $SCRIPT_DIR"
echo "  - Dotfiles directory: $DOTFILES_DIR"
if [[ ${#PACKAGES[@]} -gt 0 ]]; then
    echo "  - Available packages: ${PACKAGES[*]}"
else
    echo "  - Available packages: None found"
fi
echo "  - Management script: ~/.local/bin/dotfiles"
echo ""
echo "Next steps:"
if [[ ${#PACKAGES[@]} -gt 0 ]]; then
    echo "1. Deploy dotfiles: 'dotfiles install-all' or 'dotfiles install <package>'"
else
    echo "1. Create your dotfiles packages directly in ~/.dotfiles/:"
    echo "   mkdir -p ~/.dotfiles/{git,zsh,nvim/.config/nvim}"
    echo "2. Add your configuration files to the appropriate directories"
    echo "3. Deploy with: 'dotfiles install-all'"
fi
echo "2. Restart your terminal or run 'exec zsh' to use zsh with Nix environment"
echo "3. Configure git with: git config --global user.name 'Your Name'"
echo "4. Configure git with: git config --global user.email 'your.email@example.com'"
echo "5. Set Caskaydia Cove Nerd Font in your Windows Terminal settings"
echo ""
echo "WSL-specific notes:"
echo "- Nix packages are isolated from Ubuntu's apt packages"
echo "- Font is installed for WSL but must be configured in Windows Terminal"
echo "- Use 'dotfiles nix-update' to update all Nix packages"
echo ""
echo "Useful commands:"
echo "  - dotfiles status      # See current state and Nix packages"
echo "  - dotfiles nix-update  # Update all Nix packages"
echo "  - nix-env -q          # List installed Nix packages"
echo "  - eval \$(dotfiles cd)  # Navigate to dotfiles directory"
echo ""
log_info "Enjoy your Nix-powered WSL development environment!"