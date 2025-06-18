#!/bin/bash

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
        fonts-powerline
    
    print_success "Essential packages installed"
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
    for pkg in git zsh neovim tmux; do
        if [ -d "$script_dir/$pkg" ]; then
            available_packages+=("$pkg")
        fi
    done
    
    if [ ${#available_packages[@]} -eq 0 ]; then
        print_warning "No dotfile packages found in $script_dir"
        print_warning "Expected directories: git/, zsh/, neovim/, tmux/"
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
        echo "You can apply them later with: stow git zsh neovim tmux"
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
    install_neovim
    install_dotnet
    install_nodejs
    setup_python_tools
    setup_zsh
    setup_dotfiles
    setup_shell
    
    # Completion
    show_completion_message
}

# Run main function
main "$@"
