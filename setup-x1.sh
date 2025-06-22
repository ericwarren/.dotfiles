
# Ubuntu Development Environment Setup Script
# Designed for Ubuntu 22.04 LTS and Ubuntu 24.04 LTS
# Usage: ./ubuntu-setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
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

check_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "ubuntu" ]; then
            print_error "This script is designed for Ubuntu only"
            print_error "Detected: $PRETTY_NAME"
            exit 1
        fi
        print_success "Detected: $PRETTY_NAME"
    else
        print_error "Cannot detect Ubuntu version"
        exit 1
    fi
}

install_system_packages() {
    print_header "📦 Installing System Packages"


    echo "Updating package lists..."
    sudo apt update

    echo "Installing essential packages..."
    sudo apt install -y \
        curl wget git zsh \
        build-essential cmake \
        software-properties-common \
        apt-transport-https \
        ca-certificates gnupg \
        lsb-release unzip stow \
        python3 python3-pip python3-venv \
        tmux tree htop neofetch \
        fonts-powerline xclip xsel \
        wl-clipboard tlp tlp-rdw \
        ubuntu-restricted-extras \
        gnome-tweaks minicom

    print_success "Essential packages installed"
}

install_pfsense_qemu() {
    print_header "🔥 Installing pfSense on QEMU"

    # Install QEMU and virtualization tools
    echo "Installing QEMU and virtualization packages..."
    sudo apt install -y \
        qemu-kvm qemu-utils qemu-system-x86 \
        libvirt-daemon-system libvirt-clients \
        bridge-utils virt-manager \
        ovmf # UEFI firmware for VMs

    # Add user to libvirt group
    sudo usermod -a -G libvirt $USER
    sudo usermod -a -G kvm $USER

    print_success "QEMU and virtualization tools installed"

    # Create directory for VM images
    mkdir -p ~/VMs/pfsense
    cd ~/VMs/pfsense

    # Download pfSense ISO (latest community edition)
    echo "Downloading pfSense ISO..."
    PFSENSE_VERSION="2.7.2"  # Update this to latest version
    PFSENSE_ISO="pfSense-CE-${PFSENSE_VERSION}-RELEASE-amd64.iso"
    PFSENSE_URL="https://atxfiles.netgate.com/mirror/downloads/${PFSENSE_ISO}.gz"

    if [ ! -f "${PFSENSE_ISO}" ]; then
        wget "${PFSENSE_URL}" -O "${PFSENSE_ISO}.gz"
        gunzip "${PFSENSE_ISO}.gz"
        print_success "pfSense ISO downloaded"
    else
        print_success "pfSense ISO already exists"
    fi

    # Create virtual disk
    echo "Creating virtual disk for pfSense..."
    qemu-img create -f qcow2 pfsense.qcow2 20G

    # Create startup script
    cat > start_pfsense.sh << 'EOF'
#!/bin/bash
# pfSense QEMU startup script
# Usage: ./start_pfsense.sh [install|run]

VM_NAME="pfSense"
DISK="pfsense.qcow2"
ISO="pfSense-CE-2.7.2-RELEASE-amd64.iso"  # Update version as needed
MEMORY="2048"
CPUS="2"

# Network configuration
# Creates two networks: WAN (NAT) and LAN (internal)
WAN_NET="-netdev user,id=wan,hostfwd=tcp::8443-:443,hostfwd=tcp::8080-:80"
LAN_NET="-netdev user,id=lan,net=192.168.100.0/24,dhcpstart=192.168.100.10"

case "$1" in
    "install")
        echo "Starting pfSense installation..."
        qemu-system-x86_64 \
            -name "$VM_NAME" \
            -m "$MEMORY" \
            -smp "$CPUS" \
            -hda "$DISK" \
            -cdrom "$ISO" \
            -boot d \
            $WAN_NET -device e1000,netdev=wan \
            $LAN_NET -device e1000,netdev=lan \
            -vga std \
            -enable-kvm
        ;;
    "run"|*)
        echo "Starting pfSense..."
        qemu-system-x86_64 \
            -name "$VM_NAME" \
            -m "$MEMORY" \
            -smp "$CPUS" \
            -hda "$DISK" \
            $WAN_NET -device e1000,netdev=wan \
            $LAN_NET -device e1000,netdev=lan \
            -vga std \
            -enable-kvm \
            -daemonize
        echo "pfSense started in background"
        echo "Web interface: https://localhost:8443"
        echo "Default login: admin/pfsense"
        ;;
esac
EOF

    chmod +x start_pfsense.sh
    print_success "pfSense VM setup complete"

    echo -e "\n${GREEN}pfSense Installation Instructions:${NC}"
    echo "1. Run installation: ./start_pfsense.sh install"
    echo "2. Follow pfSense setup wizard in the VM"
    echo "3. After installation: ./start_pfsense.sh run"
    echo "4. Access web interface: https://localhost:8443"
    echo "5. Default credentials: admin/pfsense"
    echo -e "\n${YELLOW}Note: You may need to logout/login for group membership to take effect${NC}"
}

install_alacritty(){
    sudo apt install alacritty
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip
    unzip CascadiaCode.zip -d ~/.local/share/fonts/ && rm CascadiaCode.zip
    fc-cache -fv
}

install_qutebrowser() {
    print_header "🌐 Installing Qutebrowser"

    # Install Qt dependencies and development packages
    echo "Installing Qt and Python dependencies..."
    sudo apt install -y \
        python3-pip python3-venv python3-dev \
        python3-pyqt5 python3-pyqt5.qtwebengine \
        python3-pyqt5.qtwebkit python3-pyqt5.qtmultimedia \
        qtbase5-dev qtwebengine5-dev \
        python3-pyqt6 python3-pyqt6.qtwebengine

    # Create qutebrowser virtual environment
    echo "Creating qutebrowser virtual environment..."
    QUTE_VENV_DIR="$HOME/.local/share/qutebrowser-env"

    if [ -d "$QUTE_VENV_DIR" ]; then
        print_warning "Qutebrowser venv already exists, removing old installation..."
        rm -rf "$QUTE_VENV_DIR"
    fi

    # Create venv with system site packages (for Qt access)
    python3 -m venv "$QUTE_VENV_DIR" --system-site-packages

    # Activate and install qutebrowser
    echo "Installing qutebrowser in virtual environment..."
    source "$QUTE_VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install qutebrowser

    # Verify installation
    QUTE_VERSION=$("$QUTE_VENV_DIR/bin/qutebrowser" --version 2>/dev/null | head -n1 || echo "unknown")
    deactivate

    if [ "$QUTE_VERSION" != "unknown" ]; then
        print_success "Qutebrowser installed: $QUTE_VERSION"
    else
        print_error "Qutebrowser installation failed"
        return 1
    fi

    # Create convenient aliases
    echo "Setting up qutebrowser aliases..."

    # Add aliases to shell configs
    QUTE_ALIAS_NORMAL="alias qutebrowser='$QUTE_VENV_DIR/bin/qutebrowser'"
    QUTE_ALIAS_BG="alias qb='nohup $QUTE_VENV_DIR/bin/qutebrowser >/dev/null 2>&1 & disown'"

    # Add to zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "qutebrowser-env" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Qutebrowser aliases" >> "$HOME/.zshrc"
            echo "$QUTE_ALIAS_NORMAL" >> "$HOME/.zshrc"
            echo "$QUTE_ALIAS_BG" >> "$HOME/.zshrc"
            print_success "Added qutebrowser aliases to .zshrc"
        fi
    fi

    # Add to bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        if ! grep -q "qutebrowser-env" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Qutebrowser aliases" >> "$HOME/.bashrc"
            echo "$QUTE_ALIAS_NORMAL" >> "$HOME/.bashrc"
            echo "$QUTE_ALIAS_BG" >> "$HOME/.bashrc"
            print_success "Added qutebrowser aliases to .bashrc"
        fi
    fi

    # Create desktop entry for application launcher
    echo "Creating desktop entry..."
    mkdir -p "$HOME/.local/share/applications"

    cat > "$HOME/.local/share/applications/qutebrowser.desktop" << EOF
[Desktop Entry]
Name=qutebrowser
Comment=A keyboard-driven, vim-like browser
Exec=$QUTE_VENV_DIR/bin/qutebrowser %u
Icon=qutebrowser
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
EOF

    print_success "Desktop entry created for application launcher"

    # Create config directory
    mkdir -p "$HOME/.config/qutebrowser"

    print_success "Qutebrowser installation complete!"
    echo -e "\n${GREEN}Usage:${NC}"
    echo "  • qutebrowser    - Launch qutebrowser normally"
    echo "  • qb             - Launch qutebrowser in background"
    echo "  • Access via app launcher (wofi/rofi)"
    echo -e "\n${YELLOW}Note:${NC} Restart your terminal or run 'source ~/.zshrc' to use aliases"
}

install_hyprland() {
    print_header "🌊 Installing Hyprland"

    # Install Hyprland and all dependencies
    sudo apt install -y \
        hyprland waybar wofi mako-notifier grim slurp \
        thunar brightnessctl wayland-protocols \
        xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
        swaylock swayidle imagemagick

    mkdir -p ~/.local/bin

    print_success "Hyprland and dependencies installed"
}

install_neovim() {
    print_header "📝 Installing Neovim"

    # Install Neovim 0.10+ from unstable PPA for better plugin support
    echo "Adding Neovim unstable PPA..."
    sudo add-apt-repository ppa:neovim-ppa/unstable -y
    sudo apt update
    sudo apt install -y neovim

    # Verify version
    NVIM_VERSION=$(nvim --version | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    NVIM_MAJOR=$(echo $NVIM_VERSION | cut -d. -f1)
    NVIM_MINOR=$(echo $NVIM_VERSION | cut -d. -f2)

    if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 10 ]; then
        print_warning "Neovim version $NVIM_VERSION may be too old for some plugins"
    else
        print_success "Neovim $NVIM_VERSION installed"
    fi

    # Create config directory
    mkdir -p ~/.config/nvim/lua
    print_success "Neovim config directory created"
}

install_chrome() {
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/google.gpg >/dev/null
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo sudo tee /etc/apt/sources.list.d/google-chrome.list
    sudo apt update
    sudo apt install google-chrome-stable
}

install_dotnet() {
    print_header "🔷 Installing .NET SDK"

    if command -v dotnet &> /dev/null; then
        print_success ".NET SDK already installed: $(dotnet --version)"
        return
    fi

    echo "Installing Microsoft package repository..."
    UBUNTU_VERSION=$(lsb_release -rs)
    wget -q https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb

    sudo apt update
    sudo apt install -y dotnet-sdk-8.0

    print_success ".NET SDK installed: $(dotnet --version)"

    # Install useful .NET global tools
    echo "Installing .NET global tools..."
    dotnet tool install --global dotnet-ef 2>/dev/null || true
    dotnet tool install --global dotnet-outdated-tool 2>/dev/null || true
    dotnet tool install --global dotnet-format 2>/dev/null || true

    # Ensure .NET tools are in PATH
    if ! echo $PATH | grep -q "$HOME/.dotnet/tools"; then
        echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.bashrc
        print_success "Added .NET tools to PATH"
    fi

    print_success ".NET development tools installed"
}

install_nodejs() {
    print_header "📗 Installing Node.js via NVM"

    # Install NVM if not present
    if [ ! -d "$HOME/.nvm" ]; then
        echo "Installing Node Version Manager (nvm)..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

        # Source nvm for current session
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        print_success "NVM installed"
    else
        print_success "NVM already installed"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi

    # Install latest LTS Node.js
    echo "Installing latest LTS Node.js..."
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*

    NODE_VERSION=$(node --version)
    print_success "Node.js $NODE_VERSION installed"

    # Install global packages
    echo "Installing global Node.js packages..."
    npm install -g typescript ts-node yarn pnpm eslint prettier nodemon

    print_success "Node.js development tools installed"
}

setup_python_tools() {
    print_header "🐍 Setting Up Python Development Tools"

    # Install system Python packages
    sudo apt install -y python3-full python3-pip python3-venv

    # Create isolated environment for development tools
    PYTHON_TOOLS_DIR="$HOME/.local/share/python-dev-tools"

    if [ ! -d "$PYTHON_TOOLS_DIR" ]; then
        echo "Creating Python development tools environment..."
        python3 -m venv "$PYTHON_TOOLS_DIR"

        # Install tools in the virtual environment
        "$PYTHON_TOOLS_DIR/bin/pip" install \
            pipenv poetry black flake8 mypy pytest jupyter ipython

        # Create symlinks in ~/.local/bin
        mkdir -p "$HOME/.local/bin"
        for tool in pipenv poetry black flake8 mypy pytest jupyter ipython; do
            if [ -f "$PYTHON_TOOLS_DIR/bin/$tool" ]; then
                ln -sf "$PYTHON_TOOLS_DIR/bin/$tool" "$HOME/.local/bin/$tool"
            fi
        done

        print_success "Python development tools installed in isolated environment"
    else
        print_success "Python development tools already installed"
    fi
}

setup_zsh() {
    print_header "🐚 Setting Up Zsh with Oh My Zsh"

    # Install Oh My Zsh if not present
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing Oh My Zsh..."

        # Backup existing .zshrc
        if [ -f "$HOME/.zshrc" ]; then
            mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
            print_success "Backed up existing .zshrc"
        fi

        # Install Oh My Zsh
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        print_success "Oh My Zsh installed"
    else
        print_success "Oh My Zsh already installed"
    fi

    # Install useful zsh plugins
    echo "Installing zsh plugins..."

    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
    fi

    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    fi

    print_success "Zsh plugins installed"
}

setup_dotfiles() {
    print_header "🔗 Setting Up Dotfiles"

    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Check for dotfile packages
    available_packages=()
    for pkg in git zsh neovim tmux hyprland qutebrowser; do
        if [ -d "$script_dir/$pkg" ]; then
            available_packages+=("$pkg")
        fi
    done

    if [ ${#available_packages[@]} -eq 0 ]; then
        print_warning "No dotfile packages found in $script_dir"
        print_warning "Expected directories: git/, zsh/, neovim/, tmux/, hyprland/, qutebrowser/"
        return
    fi

    echo "Found dotfile packages: ${available_packages[*]}"

    # Ask user about applying dotfiles
    read -p "Apply dotfiles with Stow? (y/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$script_dir"
        for pkg in "${available_packages[@]}"; do
            echo "Applying $pkg dotfiles..."
            if stow -v "$pkg" 2>/dev/null; then
                print_success "Applied $pkg dotfiles"
            else
                print_warning "Failed to apply $pkg dotfiles (may have conflicts)"
                echo "  You can resolve conflicts manually with: stow -v $pkg"
            fi
        done
    else
        echo "Skipping dotfiles setup"
        echo "You can apply them later with: stow git zsh neovim tmux sway"
    fi
}

setup_shell() {
    print_header "🐚 Configuring Default Shell"

    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "Changing default shell to zsh..."
        chsh -s $(which zsh)
        print_success "Default shell changed to zsh"
        print_warning "You'll need to restart your terminal or logout/login for this to take effect"
    else
        print_success "Default shell is already zsh"
    fi
}

show_completion_message() {
    print_header "🎉 Setup Complete!"

    echo -e "\n${GREEN}Your Ubuntu development environment is ready!${NC}\n"

    echo "📋 What was installed:"
    echo "  • Essential development tools and packages"
    echo "  • Neovim $(nvim --version | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo 'latest')"
    echo "  • .NET SDK $(dotnet --version 2>/dev/null || echo 'latest')"
    echo "  • Node.js $(node --version 2>/dev/null || echo 'latest') via NVM"
    echo "  • pfSense virtualization environment (QEMU/KVM)"
    echo "  • Python development tools (isolated environment)"
    echo "  • Zsh with Oh My Zsh"

    echo -e "\n📌 Next Steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Open Neovim and run :checkhealth to verify setup"

    echo -e "\n💡 Useful commands:"
    echo "  • nvm list         - Show installed Node.js versions"
    echo "  • dotnet --info    - Show .NET information"
    echo "  • nvim --version   - Check Neovim version"

    if [ "$SHELL" != "$(which zsh)" ]; then
        echo -e "\n${YELLOW}⚠️  Remember to restart your terminal for the shell change to take effect!${NC}"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Ubuntu Development Environment Setup${NC}"
    echo "=============================================="

    # Preliminary checks
    check_ubuntu_version

    # Installation steps
    install_system_packages
    install_chrome
    install_alacritty
    install_qutebrowser
    install_neovim
    install_dotnet
    install_nodejs
    setup_python_tools
    setup_zsh
    install_pfsense_qemu
    setup_dotfiles
    setup_shell

    # Completion
    show_completion_message
}

# Run main function
main "$@"
