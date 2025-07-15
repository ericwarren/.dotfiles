#!/bin/bash

# Ubuntu Development Environment Setup Script for WSL
# Designed for Ubuntu 22.04/24.04 on Windows Subsystem for Linux
# Usage: ./setup-WSL-ubuntu.sh

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

    echo "Installing build-essential..."
    sudo apt install -y build-essential

    echo "Installing essential packages..."
    sudo apt install -y \
        curl wget git zsh \
        ca-certificates gnupg \
        unzip stow snapd \
        python3 python3-pip python3-venv \
        tmux tree htop \
        fonts-font-awesome fonts-powerline \
        wl-clipboard xclip \
        minicom ranger openssh-client jq fzf bat \
        zoxide ripgrep

    sudo apt upgrade -y

    # Install Cascadia Code Nerd Font manually
    echo "Installing Cascadia Code Nerd Font..."
    mkdir -p ~/.local/share/fonts
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaCode.zip
    unzip CascadiaCode.zip -d ~/.local/share/fonts/ && rm CascadiaCode.zip
    fc-cache -fv

    print_success "Essential packages and fonts installed"
}

install_neovim() {
    print_header "📝 Installing Neovim"

    # Install latest stable Neovim from official PPA
    sudo add-apt-repository -y ppa:neovim-ppa/stable
    sudo apt update
    sudo apt install -y neovim

    # Verify version
    NVIM_VERSION=$(nvim --version | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    print_success "Neovim $NVIM_VERSION installed"

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

    # Download Microsoft repository GPG keys
    wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb

    # Update package lists
    sudo apt update

    # Install .NET SDK
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

install_docker() {
    print_header "🐳 Installing Docker"

    if command -v docker &> /dev/null; then
        print_success "Docker already installed: $(docker --version)"
        return
    fi

    # Remove any old Docker installations
    echo "Removing old Docker installations..."
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Install prerequisites
    sudo apt update
    sudo apt install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    echo "Adding Docker GPG key..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo "Adding Docker repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    echo "Installing Docker Engine..."
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    echo "Adding $USER to docker group..."
    sudo usermod -aG docker $USER

    # Enable and start Docker service
    echo "Enabling Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker

    # Verify installation
    DOCKER_VERSION=$(docker --version)
    COMPOSE_VERSION=$(docker compose version)

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

    # Download and install latest Go
    GO_VERSION="1.22.0"
    wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
    rm go${GO_VERSION}.linux-amd64.tar.gz

    # Add to PATH
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    fi

    # Set up Go environment
    if ! grep -q "GOPATH" ~/.bashrc; then
        echo 'export GOPATH=$HOME/go' >> ~/.bashrc
        echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
        print_success "Added Go environment variables to .bashrc"
    fi

    # Source for current session
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin

    print_success "Go installed: $(go version)"
}

install_emacs() {
    print_header "📝 Installing Emacs 30.1 from Source"

    if command -v emacs &> /dev/null; then
        print_success "Emacs already installed: $(emacs --version | head -n1)"
        return
    fi

    # Install build dependencies
    echo "Installing Emacs build dependencies..."
    sudo sudo apt install -y build-essential autoconf \
        libtool texinfo libxpm-dev libjpeg-dev libpng-dev \
        libgif-dev libtiff-dev libgnutls28-dev libxml2-dev \
        libgtk-3-dev libncurses-dev libgccjit-13-dev \
        libjansson-dev libsqlite3-dev libgpm-dev \
        libmagickwand-dev imagemagick libtree-sitter-dev

    # Set GCC version for native compilation
    export CC=gcc-10 CXX=g++-10

    # Create temporary build directory
    EMACS_BUILD_DIR=$(mktemp -d)
    cd "$EMACS_BUILD_DIR"

    # Download Emacs 30.1 source
    echo "Downloading Emacs 30.1 source..."
    wget https://ftp.gnu.org/gnu/emacs/emacs-30.1.tar.xz
    tar -xf emacs-30.1.tar.xz
    cd emacs-30.1

    # Configure build with native compilation and GUI support
    echo "Configuring Emacs build..."
    ./configure \
        --prefix=/usr \
        --with-x-toolkit=gtk3 \
        --with-xpm \
        --with-jpeg \
        --with-png \
        --with-gif \
        --with-tiff \
        --with-gnutls \
        --with-xml2 \
        --with-cairo \
        --with-harfbuzz \
        --with-rsvg \
        --with-libsystemd \
        --with-imagemagick \
        --with-native-compilation=yes \
        --with-json \
        --with-sqlite3 \
        --with-tree-sitter

    # Build Emacs (this will take a while)
    echo "Building Emacs (this may take 15-30 minutes)..."
    make -j$(nproc)

    # Install Emacs
    echo "Installing Emacs..."
    sudo make install

    # Clean up build directory
    cd ~
    rm -rf "$EMACS_BUILD_DIR"

    # Verify installation
    if command -v emacs &> /dev/null; then
        print_success "Emacs installed: $(emacs --version | head -n1)"
    else
        print_error "Emacs installation failed"
        return 1
    fi
}

install_doom_emacs() {
    print_header "🔥 Installing Doom Emacs"

    # Install dependencies for Doom Emacs
    echo "Installing Doom Emacs dependencies..."
    sudo apt install -y git ripgrep fd-find

    print_success "Doom Emacs dependencies installed"

    # Remove existing Emacs config if present
    if [ -d "$HOME/.config/emacs" ] || [ -d "$HOME/.emacs.d" ]; then
        echo "Backing up existing Emacs configuration..."
        [ -d "$HOME/.config/emacs" ] && mv "$HOME/.config/emacs" "$HOME/.config/emacs.bak.$(date +%Y%m%d%H%M%S)"
        [ -d "$HOME/.emacs.d" ] && mv "$HOME/.emacs.d" "$HOME/.emacs.d.bak.$(date +%Y%m%d%H%M%S)"
    fi

    # Clone Doom Emacs to ~/.config/emacs
    echo "Cloning Doom Emacs repository..."
    if git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs; then
        print_success "Doom Emacs repository cloned"

        # Set DOOMDIR to use our stowed config location
        export DOOMDIR="$HOME/.config/doom"

        # Run Doom install script
        echo "Running Doom install script (this may take a while)..."
        if DOOMDIR="$HOME/.config/doom" ~/.config/emacs/bin/doom install; then
            print_success "Doom Emacs installed successfully"

            # Add doom to PATH in current session
            export PATH="$HOME/.config/emacs/bin:$PATH"
            print_success "Doom binary added to PATH for current session"
        else
            print_error "Failed to run Doom install script"
            return 1
        fi
    else
        print_error "Failed to clone Doom Emacs repository"
        return 1
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

    # Install Claude Code
    echo "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code

    print_success "Node.js development tools installed"
    print_success "Claude Code installed"
}

install_dropbox() {
    print_header "💧 Installing Dropbox"

    echo "Downloading Dropbox daemon..."
    cd ~
    wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
    print_success "Dropbox daemon downloaded and extracted"

    # Download dropbox.py to the stow folder
    echo "Downloading dropbox.py CLI tool..."
    mkdir -p dropbox/.local/bin
    wget -O dropbox/.local/bin/dropbox.py "https://www.dropbox.com/download?dl=packages/dropbox.py"
    chmod +x dropbox/.local/bin/dropbox.py
    print_success "dropbox.py CLI tool downloaded"
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

    # Add Doom Emacs bin to PATH in .zshrc if not already present
    if [ -d "$HOME/.config/emacs/bin" ] && ! grep -q "\.config/emacs/bin" "$HOME/.zshrc" 2>/dev/null; then
        echo "" >> "$HOME/.zshrc"
        echo '# Doom Emacs' >> "$HOME/.zshrc"
        echo 'export PATH="$HOME/.config/emacs/bin:$PATH"' >> "$HOME/.zshrc"
        print_success "Added Doom Emacs bin to PATH in .zshrc"
    fi

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

    echo -e "\n${GREEN}Your Ubuntu WSL development environment is ready!${NC}\n"

    echo "📋 What was installed:"
    echo "  • Essential development tools and packages"
    echo "  • Neovim $(nvim --version | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo 'latest')"
    echo "  • Emacs $(emacs --version 2>/dev/null | head -n1 | grep -oP '\d+\.\d+' || echo 'latest') with Doom"
    echo "  • .NET SDK $(dotnet --version 2>/dev/null || echo 'latest')"
    echo "  • Docker Engine $(docker --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo 'latest')"
    echo "  • Go $(go version 2>/dev/null | grep -oP 'go\d+\.\d+\.\d+' || echo 'latest')"
    echo "  • Node.js $(node --version 2>/dev/null || echo 'latest') via NVM"
    echo "  • Claude Code CLI"
    echo "  • Python 3 with pip and venv"
    echo "  • Zsh with Oh My Zsh and Starship prompt"
    echo "  • Dropbox daemon and CLI tool"

    echo -e "\n📌 Next Steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Open Neovim and run :checkhealth to verify setup"
    echo "  3. After stowing emacs config, run: doom sync"
    echo "  4. Stow Dropbox configs: stow dropbox"
    echo "  5. Enable Dropbox user service: systemctl --user enable dropbox.service"
    echo "  6. Start Dropbox user service: systemctl --user start dropbox.service"
    echo "  7. Reload systemd user daemon: systemctl --user daemon-reexec"
    echo "  8. Enable and start Emacs service: systemctl --user enable --now emacs.service"

    echo -e "\n💡 Useful commands:"
    echo "  • nvm list         - Show installed Node.js versions"
    echo "  • dotnet --info    - Show .NET information"
    echo "  • docker --version - Check Docker version"
    echo "  • go version       - Check Go version"
    echo "  • claude --version - Check Claude Code version"
    echo "  • starship --version - Check Starship version"
    echo "  • nvim --version   - Check Neovim version"
    echo "  • emacs --version  - Check Emacs version"
    echo "  • doom doctor      - Check Doom Emacs health"

    if [ "$SHELL" != "$(which zsh)" ]; then
        echo -e "\n${YELLOW}⚠️  Remember to restart your terminal for the shell change to take effect!${NC}"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Ubuntu WSL Development Environment Setup${NC}"
    echo "=============================================="

    # Preliminary checks
    check_ubuntu_version

    # Installation steps
    install_system_packages
    install_neovim
    install_emacs
    install_doom_emacs
    install_dotnet
    install_docker
    install_go
    install_nodejs
    install_dropbox
    setup_zsh
    setup_dotfiles
    setup_shell

    # Completion
    show_completion_message
}

# Run main function
main "$@"
