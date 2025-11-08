#!/bin/bash

# Fedora Development Environment Setup Script
# Designed for Fedora 40+ on Lenovo X1 Carbon Gen 9
# Usage: ./setup-X1-fedora.sh

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

check_fedora_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" != "fedora" ]; then
            print_error "This script is designed for Fedora only"
            print_error "Detected: $PRETTY_NAME"
            exit 1
        fi
        print_success "Detected: $PRETTY_NAME"
    else
        print_error "Cannot detect Fedora version"
        exit 1
    fi
}

install_system_packages() {
    print_header "📦 Installing System Packages"

    echo "Updating package lists..."
    sudo dnf update -y

    echo "Installing development tools group..."
    sudo dnf group install -y development-tools

    echo "Installing essential packages..."
    sudo dnf install -y \
        curl wget git zsh \
        ca-certificates gnupg \
        unzip stow \
        python3 python3-pip python3-virtualenv \
        tmux tree htop \
        fontawesome-fonts powerline-fonts \
        wl-clipboard xclip \
        minicom ranger openssh jq fzf bg \
        zoxide ripgrep

    # Install RPM Fusion repositories for additional codecs
    echo "Installing RPM Fusion repositories..."
    sudo dnf install -y \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    sudo dnf update -y

    print_success "Essential packages installed"
}

install_alacritty() {
    print_header "🖥️ Installing Alacritty"

    sudo dnf install -y alacritty

    echo "Installing fonts..."

    # Install Cascadia Code Nerd Font manually
    echo "Installing Cascadia Code Nerd Font..."
    mkdir -p ~/.local/share/fonts
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip
    unzip CascadiaCode.zip -d ~/.local/share/fonts/ && rm CascadiaCode.zip
    fc-cache -fv

    print_success "Alacritty and fonts installed (Cascadia Code Nerd Font, Noto fonts)"
}

install_neovim() {
    print_header "📝 Installing Neovim"

    sudo dnf install -y neovim

    # Verify version
    NVIM_VERSION=$(nvim --version | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    print_success "Neovim $NVIM_VERSION installed"

    # Create config directory
    mkdir -p ~/.config/nvim/lua
    print_success "Neovim config directory created"
}

install_chrome() {
    print_header "🌐 Installing Google Chrome"

    if command -v google-chrome &> /dev/null; then
        print_success "Google Chrome already installed: $(google-chrome --version)"
        return
    fi

    echo "Installing Google Chrome repository..."
    sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub
    sudo tee /etc/yum.repos.d/google-chrome.repo << 'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

    sudo dnf install -y google-chrome-stable

    print_success "Google Chrome installed: $(google-chrome --version)"
}

install_vscode() {
    print_header "💻 Installing Visual Studio Code"

    if command -v code &> /dev/null; then
        print_success "Visual Studio Code already installed: $(code --version | head -n1)"
        return
    fi

    echo "Installing Visual Studio Code repository..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo tee /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

    sudo dnf install -y code

    print_success "Visual Studio Code installed: $(code --version | head -n1)"
}

install_dotnet() {
    print_header "🔷 Installing .NET SDK"

    if command -v dotnet &> /dev/null; then
        print_success ".NET SDK already installed: $(dotnet --version)"
        return
    fi

    echo "Installing Microsoft package repository..."

    sudo dnf install -y dotnet-sdk-8.0

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

install_docker() {
    print_header "🐳 Installing Docker"

    if command -v docker &> /dev/null; then
        print_success "Docker already installed: $(docker --version)"
        return
    fi

    # Remove any old Docker installations
    echo "Removing old Docker installations..."
    sudo dnf remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine 2>/dev/null || true

    # Install Docker from Fedora repositories
    echo "Installing Docker Engine..."
    sudo dnf install -y docker docker-compose

    # Add user to docker group
    echo "Adding $USER to docker group..."
    sudo usermod -aG docker $USER

    # Enable and start Docker service
    echo "Enabling Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker

    # Verify installation
    DOCKER_VERSION=$(docker --version)
    COMPOSE_VERSION=$(docker-compose --version)

    print_success "Docker installed: $DOCKER_VERSION"
    print_success "Docker Compose installed: $COMPOSE_VERSION"

    print_warning "You'll need to logout/login for docker group membership to take effect"
    print_success "Docker installation complete"
}

install_go() {
    print_header "🐹 Installing Go"

    if command -v go &> /dev/null; then
        print_success "Go already installed: $(go version)"
        return
    fi

    sudo dnf install -y golang

    print_success "Go installed: $(go version)"

    # Set up Go environment
    if ! grep -q "GOPATH" ~/.bashrc; then
        echo 'export GOPATH=$HOME/go' >> ~/.bashrc
        echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
        print_success "Added Go environment variables to .bashrc"
    fi
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

install_claude_code() {
    print_header "🤖 Installing Claude Code"

    if command -v claude &> /dev/null; then
        print_success "Claude Code already installed: $(claude --version 2>/dev/null || echo 'installed')"
        return
    fi

    echo "Installing Claude Code..."
    if curl -fsSL https://claude.ai/install.sh | bash; then
        print_success "Claude Code installed successfully"
    else
        print_error "Failed to install Claude Code"
        return 1
    fi

    # Verify installation
    if command -v claude &> /dev/null; then
        CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "latest")
        print_success "Claude Code installed: $CLAUDE_VERSION"
    else
        print_warning "Claude Code installation may require a new shell session"
    fi
}

install_azure_cli() {
    print_header "☁️ Installing Azure CLI"

    if command -v az &> /dev/null; then
        print_success "Azure CLI already installed: $(az version --output tsv --query '\"azure-cli\"' 2>/dev/null || echo 'installed')"
        return
    fi

    echo "Installing Azure CLI repository..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

    sudo tee /etc/yum.repos.d/azure-cli.repo << 'EOF'
[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

    echo "Installing Azure CLI..."
    sudo dnf install -y azure-cli

    print_success "Azure CLI installed: $(az version --output tsv --query '\"azure-cli\"' 2>/dev/null || echo 'successfully')"
}

install_github_cli() {
    print_header "🐙 Installing GitHub CLI"

    if command -v gh &> /dev/null; then
        print_success "GitHub CLI already installed: $(gh --version | head -n1)"
        return
    fi

    echo "Installing GitHub CLI..."
    sudo dnf install -y gh

    print_success "GitHub CLI installed: $(gh --version | head -n1)"
}

setup_zsh() {
    print_header "🐚 Setting Up Zsh with Oh My Zsh and Starship"

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

    # Check if starship is already installed
    if command -v starship &> /dev/null; then
        print_success "Starship already installed: $(starship --version)"
        return
    fi

    echo "Installing Starship prompt..."

    # Install starship using the official installer
    if curl -sS https://starship.rs/install.sh | sh; then
        print_success "Starship installed successfully"
    else
        print_error "Failed to install Starship"
        return 1
    fi

    # Verify installation
    if command -v starship &> /dev/null; then
        STARSHIP_VERSION=$(starship --version | head -n1)
        print_success "Starship installed: $STARSHIP_VERSION"
    else
        print_error "Starship installation verification failed"
        return 1
    fi
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

    echo -e "\n${GREEN}Your Fedora development environment is ready!${NC}\n"

    echo "📋 What was installed:"
    echo "  • Essential development tools and packages"
    echo "  • Alacritty terminal emulator with Cascadia Code Nerd Font"
    echo "  • Neovim $(nvim --version | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo 'latest')"
    echo "  • Google Chrome $(google-chrome --version 2>/dev/null || echo 'latest')"
    echo "  • Visual Studio Code $(code --version 2>/dev/null | head -n1 || echo 'latest')"
    echo "  • .NET SDK $(dotnet --version 2>/dev/null || echo 'latest')"
    echo "  • Docker Engine $(docker --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo 'latest')"
    echo "  • Go $(go version 2>/dev/null | grep -oP 'go\d+\.\d+\.\d+' || echo 'latest')"
    echo "  • Node.js $(node --version 2>/dev/null || echo 'latest') via NVM"
    echo "  • Claude Code CLI"
    echo "  • Azure CLI $(az version --output tsv --query '\"azure-cli\"' 2>/dev/null || echo 'latest')"
    echo "  • GitHub CLI $(gh --version 2>/dev/null | head -n1 | awk '{print $3}' || echo 'latest')"
    echo "  • Python 3 with pip and virtualenv"
    echo "  • Zsh with Oh My Zsh and Starship prompt"

    echo -e "\n📌 Next Steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Open Neovim and run :checkhealth to verify setup"

    echo -e "\n💡 Useful commands:"
    echo "  • nvm list         - Show installed Node.js versions"
    echo "  • dotnet --info    - Show .NET information"
    echo "  • docker --version - Check Docker version"
    echo "  • go version       - Check Go version"
    echo "  • code --version   - Check Visual Studio Code version"
    echo "  • claude --version - Check Claude Code version"
    echo "  • az login         - Login to Azure"
    echo "  • az --version     - Check Azure CLI version"
    echo "  • gh auth login    - Authenticate with GitHub"
    echo "  • gh --version     - Check GitHub CLI version"
    echo "  • starship --version - Check Starship version"
    echo "  • nvim --version   - Check Neovim version"

    if [ "$SHELL" != "$(which zsh)" ]; then
        echo -e "\n${YELLOW}⚠️  Remember to restart your terminal for the shell change to take effect!${NC}"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Fedora Development Environment Setup${NC}"
    echo "=============================================="

    # Preliminary checks
    check_fedora_version

    # Installation steps
    install_system_packages
    install_alacritty
    install_neovim
    install_chrome
    install_vscode
    install_dotnet
    install_docker
    install_go
    install_nodejs
    install_claude_code
    install_azure_cli
    install_github_cli
    setup_zsh
    setup_dotfiles
    setup_shell

    # Completion
    show_completion_message
}

# Run main function
main "$@"
