#!/bin/bash

# Kubuntu Development Environment Setup Script
# Designed for Kubuntu 24.04 LTS on Lenovo X1 Carbon Gen 9
# Usage: ./setup-X1-kubuntu.sh

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
        if [ "$ID" != "ubuntu" ] && [ "$ID" != "kubuntu" ]; then
            print_error "This script is designed for Ubuntu/Kubuntu only"
            print_error "Detected: $PRETTY_NAME"
            exit 1
        fi
        print_success "Detected: $PRETTY_NAME"
    else
        print_error "Cannot detect Ubuntu/Kubuntu version"
        exit 1
    fi
}

install_system_packages() {
    print_header "📦 Installing System Packages"

    echo "Updating package lists..."
    sudo apt update

    echo "Installing build essentials..."
    sudo apt install -y build-essential

    echo "Installing essential packages..."
    sudo apt install -y \
        curl wget git zsh \
        ca-certificates gnupg \
        unzip stow \
        tmux tree htop ncdu \
        fonts-powerline \
        wl-clipboard xclip \
        minicom ranger openssh-client jq fzf \
        zoxide ripgrep eza bat fd-find \
        lsb-release

    echo "Installing C/C++ toolchain (clang/clangd/clang-format/lldb)..."
    sudo apt install -y clang clangd clang-format lldb

    sudo apt upgrade -y

    print_success "Essential packages installed"
}

install_python() {
    print_header "🐍 Installing Python & uv Package Manager"

    echo "Installing Python 3 and dependencies..."
    sudo apt install -y python3-full python3-pip python3-venv python-is-python3

    print_success "Python installed: $(python --version)"

    if command -v uv &> /dev/null; then
        print_success "uv already installed: $(uv --version)"
        return
    fi

    echo "Installing uv package manager..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Add to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"

    if command -v uv &> /dev/null; then
        print_success "uv installed: $(uv --version)"
    else
        print_warning "uv installed but may need PATH update. Restart your shell."
    fi
}

install_alacritty() {
    print_header "🖥️ Installing Alacritty"

    sudo apt install -y alacritty

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

    # Add Neovim unstable PPA for latest version (0.10+)
    echo "Adding Neovim unstable PPA..."
    sudo add-apt-repository ppa:neovim-ppa/unstable -y
    sudo apt update

    if command -v nvim &> /dev/null; then
        print_success "Neovim already installed, upgrading if needed..."
        sudo apt install -y neovim ripgrep fd-find
    else
        echo "Installing Neovim from PPA..."
        sudo apt install -y neovim ripgrep fd-find
    fi

    print_success "Neovim installed: $(nvim --version | head -n1)"
    print_success "Neovim configuration will be managed via stow (neovim package)"

    # Create config directory
    mkdir -p ~/.config/nvim/lua
}

install_chrome() {
    print_header "🌐 Installing Google Chrome"

    if command -v google-chrome &> /dev/null; then
        print_success "Google Chrome already installed: $(google-chrome --version)"
        return
    fi

    echo "Installing Google Chrome repository..."
    sudo curl -fsSLo /usr/share/keyrings/google-chrome-keyring.gpg https://dl.google.com/linux/keys/google-linux-signing-key.pub
    sudo tee /etc/apt/sources.list.d/google-chrome.list << 'EOF'
deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main
EOF

    sudo apt update
    sudo apt install -y google-chrome-stable

    print_success "Google Chrome installed: $(google-chrome --version)"
}

install_vscode() {
    print_header "💻 Installing Visual Studio Code"

    if command -v code &> /dev/null; then
        print_success "Visual Studio Code already installed: $(code --version | head -n1)"
        return
    fi

    echo "Installing Visual Studio Code repository..."
    sudo install -d /etc/apt/keyrings
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
    sudo tee /etc/apt/sources.list.d/vscode.list << 'EOF'
deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main
EOF

    sudo apt update
    sudo apt install -y code

    print_success "Visual Studio Code installed: $(code --version | head -n1)"
}

install_dotnet() {
    print_header "🔷 Installing .NET SDK"

    if command -v dotnet &> /dev/null; then
        print_success ".NET SDK detected: $(dotnet --version)"
    else
        print_warning ".NET SDK not detected, proceeding with installation"
    fi

    UBUNTU_VERSION="$(lsb_release -rs 2>/dev/null || echo "")"
    if [[ "$UBUNTU_VERSION" == "22.04" || "$UBUNTU_VERSION" == "24.04" ]]; then
        if ! grep -R "dotnet/backports" /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null | grep -q "dotnet/backports"; then
            echo "Adding Ubuntu .NET backports repository for .NET 9 and 10..."
            sudo add-apt-repository -y ppa:dotnet/backports
        else
            print_success "Ubuntu .NET backports repository already configured"
        fi
    else
        print_warning "Ubuntu release $UBUNTU_VERSION not explicitly handled. Attempting installation with current repositories."
    fi

    echo "Updating package lists..."
    sudo apt-get update

    for sdk_version in 8.0 9.0 10.0; do
        echo "Installing .NET SDK ${sdk_version}..."
        if sudo apt-get install -y "dotnet-sdk-${sdk_version}"; then
            print_success ".NET SDK ${sdk_version} installed"
        else
            print_warning ".NET SDK ${sdk_version} isn't available in the configured feeds yet"
        fi
    done

    DOTNET_SDKS=$(dotnet --list-sdks 2>/dev/null | paste -sd ', ' -)
    if [ -n "$DOTNET_SDKS" ]; then
        print_success ".NET SDKs installed: $DOTNET_SDKS"
    else
        print_success ".NET SDK installation complete"
    fi

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
    sudo apt remove -y docker.io docker-doc docker-compose podman-docker containerd runc 2>/dev/null || true

    # Install Docker from official repository
    echo "Installing Docker Engine..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

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
    COMPOSE_VERSION=$(docker compose version 2>/dev/null || echo "not found")

    print_success "Docker installed: $DOCKER_VERSION"
    print_success "Docker Compose installed: $COMPOSE_VERSION"

    if sudo docker ps >/dev/null 2>&1; then
        print_success "docker ps ran successfully (daemon responding)"
    else
        print_warning "docker ps failed; try rerunning with sudo or check dockerd status"
    fi

    if sudo docker info >/dev/null 2>&1; then
        print_success "docker info ran successfully"
    else
        print_warning "docker info failed; verify Docker daemon is running"
    fi

    if command -v loginctl &> /dev/null; then
        if sudo loginctl enable-linger "$USER" >/dev/null 2>&1; then
            print_success "Enabled lingering for $USER so dockerd stays available after reboot"
        else
            print_warning "Could not enable lingering via loginctl (may already be set)"
        fi
    fi

    print_warning "Log out and back in for docker group membership to take effect"
    print_success "Docker installation complete"
}

install_go() {
    print_header "🐹 Installing Go"

    if command -v go &> /dev/null; then
        print_success "Go already installed: $(go version)"
        return
    fi

    # Get the latest Go version
    echo "Fetching latest Go version..."
    GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n1)

    if [ -z "$GO_VERSION" ]; then
        print_error "Failed to fetch Go version, using fallback"
        GO_VERSION="go1.23.5"
    fi

    echo "Downloading Go ${GO_VERSION}..."
    wget "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz" -O /tmp/go.tar.gz

    echo "Removing old Go installation if present..."
    sudo rm -rf /usr/local/go

    echo "Installing Go..."
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz

    # Add Go paths to both bash and zsh configs
    local rc_file
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$rc_file" ] || touch "$rc_file"

        local go_lines=()
        if ! grep -qs '/usr/local/go/bin' "$rc_file"; then
            go_lines+=('export PATH=$PATH:/usr/local/go/bin')
        fi
        if ! grep -qs '$HOME/go/bin' "$rc_file"; then
            go_lines+=('export PATH=$PATH:$HOME/go/bin')
        fi

        if [ ${#go_lines[@]} -gt 0 ]; then
            {
                echo ''
                echo '# Go paths added by setup-X1-kubuntu.sh'
                for line in "${go_lines[@]}"; do
                    echo "$line"
                done
            } >> "$rc_file"
            print_success "Added Go PATH entries to ${rc_file##*/}"
        else
            print_success "Go PATH entries already present in ${rc_file##*/}"
        fi
    done

    # Export for current session
    export PATH=$PATH:/usr/local/go/bin
    export PATH=$PATH:$HOME/go/bin

    print_success "Go installed: $(go version)"
}

install_nodejs() {
    print_header "📗 Installing Node.js via NVM"

    # Install NVM if not present
    export NVM_DIR="$HOME/.nvm"

    if [ ! -d "$NVM_DIR" ]; then
        echo "Installing Node Version Manager (nvm)..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        print_success "NVM installed"
    else
        print_success "NVM already installed"
    fi

    # Source nvm for current session
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install latest LTS Node.js
    echo "Installing latest LTS Node.js..."
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*

    NODE_VERSION=$(node --version)
    print_success "Node.js $NODE_VERSION installed"

    echo "Enabling Corepack for Yarn/Pnpm shims..."
    if corepack enable 2>/dev/null; then
        print_success "Corepack enabled (Yarn/Pnpm tied to Node LTS)"
    else
        print_warning "Corepack enable failed; Yarn/Pnpm may need manual setup"
    fi

    # Install a few ubiquitous global tools
    npm install -g typescript ts-node eslint prettier nodemon >/dev/null 2>&1 || true
    print_success "Node.js development tools installed"
}

install_claude_code() {
    print_header "🤖 Installing Claude Code"

    if command -v claude &> /dev/null; then
        print_success "Claude Code already installed: $(claude --version 2>/dev/null || echo 'installed')"
        return
    fi

    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash

    # Add to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"

    if command -v claude &> /dev/null; then
        print_success "Claude Code installed: $(claude --version 2>/dev/null || echo 'successfully')"
    else
        print_warning "Claude Code installed but may need PATH update. Restart your shell."
    fi
}

install_azure_cli() {
    print_header "☁️ Installing Azure CLI"

    if command -v az &> /dev/null; then
        print_success "Azure CLI already installed: $(az version --output tsv --query '\"azure-cli\"' 2>/dev/null || echo 'installed')"
        return
    fi

    echo "Installing prerequisites..."
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

    echo "Adding Microsoft GPG key..."
    sudo mkdir -p /etc/apt/keyrings
    curl -sLS https://packages.microsoft.com/keys/microsoft.asc | \
        gpg --dearmor | \
        sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/microsoft.gpg

    echo "Adding Azure CLI repository..."
    AZ_DIST=$(lsb_release -cs)

    # Microsoft doesn't always have packages for the latest Ubuntu releases
    # Map to the latest supported version if needed
    case "$AZ_DIST" in
        questing|*25.*)
            # Ubuntu 25.x - use 24.04 LTS repository
            AZ_DIST="noble"
            print_warning "Using noble (24.04) repository for Azure CLI (questing/25.x not yet supported)"
            ;;
        oracular|*24.10*)
            # Ubuntu 24.10 - use 24.04 LTS repository
            AZ_DIST="noble"
            print_warning "Using noble (24.04) repository for Azure CLI (oracular/24.10 not yet supported)"
            ;;
    esac

    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" | \
        sudo tee /etc/apt/sources.list.d/azure-cli.list

    echo "Installing Azure CLI..."
    sudo apt update
    sudo apt install -y azure-cli

    print_success "Azure CLI installed: $(az version --output tsv --query '\"azure-cli\"' 2>/dev/null || echo 'successfully')"
}

install_github_cli() {
    print_header "🐙 Installing GitHub CLI"

    if command -v gh &> /dev/null; then
        print_success "GitHub CLI already installed: $(gh --version | head -n1)"
        return
    fi

    echo "Adding GitHub CLI repository..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    echo "Installing GitHub CLI..."
    sudo apt update
    sudo apt install -y gh

    print_success "GitHub CLI installed: $(gh --version | head -n1)"
}

install_tpm() {
    print_header "🔌 Installing Tmux Plugin Manager (TPM)"

    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        print_success "TPM already installed"
        return
    fi

    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    print_success "TPM installed successfully"
    print_warning "After stowing tmux config, press Ctrl+Space then I to install plugins"
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
    print_header "🐚 Setting Up Zsh Shell with Oh My Zsh and Starship"

    # Install Oh My Zsh
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

    # Install zsh plugins
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        echo "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        print_success "zsh-autosuggestions installed"
    else
        print_success "zsh-autosuggestions already installed"
    fi

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        echo "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting installed"
    else
        print_success "zsh-syntax-highlighting already installed"
    fi

    print_success "Zsh plugins installed (configure via stow)"

    # Install Starship prompt
    if command -v starship &> /dev/null; then
        print_success "Starship already installed: $(starship --version)"
    else
        echo "Installing Starship prompt..."
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
    fi

    # Change default shell to zsh
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

    echo -e "\n${GREEN}Your Kubuntu development environment is ready!${NC}\n"

    echo "📋 What was installed:"
    echo "  • Essential development tools and packages"
    echo "  • Python 3 with uv package manager $(uv --version 2>/dev/null || echo 'latest')"
    DOTNET_SUMMARY=$(dotnet --list-sdks 2>/dev/null | head -n5 | paste -sd ', ' -)
    echo "  • .NET SDKs ${DOTNET_SUMMARY:-installed}"
    echo "  • Go $(go version 2>/dev/null | awk '{print $3}' || echo 'latest')"
    echo "  • Node Version Manager (nvm) with Node.js LTS"
    echo "  • Modern CLI tools: fzf, bat, eza, htop, ncdu, tldr, jq, tree, ripgrep"
    echo "  • Alacritty terminal emulator with Cascadia Code Nerd Font"
    echo "  • Google Chrome $(google-chrome --version 2>/dev/null || echo 'latest')"
    echo "  • Visual Studio Code $(code --version 2>/dev/null | head -n1 || echo 'latest')"
    echo "  • Docker Engine $(docker --version 2>/dev/null || echo 'latest')"
    echo "  • Zsh with Oh My Zsh + plugins:"
    echo "    - zsh-autosuggestions (command suggestions)"
    echo "    - zsh-syntax-highlighting (syntax coloring)"
    echo "    - git, z, sudo, extract, colored-man-pages, dotnet"
    echo "  • Starship prompt $(starship --version 2>/dev/null | head -n1 || echo 'latest')"
    echo "  • Claude Code $(claude --version 2>/dev/null || echo 'latest')"
    echo "  • Azure CLI $(az version --output tsv --query '\"azure-cli\"' 2>/dev/null || echo 'latest')"
    echo "  • GitHub CLI $(gh --version 2>/dev/null | head -n1 | awk '{print $3}' || echo 'latest')"
    echo "  • Neovim $(nvim --version 2>/dev/null | head -n1 || echo 'latest')"

    echo -e "\n📌 Next Steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Authenticate Claude Code: claude auth"
    echo "  3. Apply your dotfiles with stow:"
    echo "     cd ~/.dotfiles && stow zsh git neovim tmux claude"
    echo "  4. Launch nvim to auto-install plugins (first run will take a moment)"

    echo -e "\n💡 Useful commands:"
    echo "  • claude             - Launch Claude Code CLI"
    echo "  • nvim               - Launch Neovim"
    echo "  • <Space>e           - Toggle file explorer (in nvim)"
    echo "  • <Space>ff          - Find files (in nvim)"
    echo "  • <Space>fg          - Live grep (in nvim)"
    echo "  • az login           - Login to Azure"
    echo "  • az --version       - Check Azure CLI version"
    echo "  • gh auth login      - Authenticate with GitHub"
    echo "  • gh --version       - Check GitHub CLI version"
    echo "  • nvm install <ver>  - Install specific Node.js version"
    echo "  • nvm use <ver>      - Switch Node.js version"
    echo "  • nvm ls             - List installed Node.js versions"
    echo "  • uv venv            - Create Python virtual environment"
    echo "  • uv pip install     - Install Python packages (fast!)"
    echo "  • fzf                - Fuzzy finder (Ctrl+R for history search)"
    echo "  • bat <file>         - Cat with syntax highlighting (after stowing zsh)"
    echo "  • rg <pattern>       - Fast recursive search (ripgrep)"
    echo "  • eza -la            - Modern ls replacement"
    echo "  • ncdu               - Disk usage analyzer"
    echo "  • tldr <command>     - Simplified man pages"
    echo "  • dotnet --info      - Show .NET information"
    echo "  • go version         - Check Go version"
    echo "  • go mod init        - Initialize Go module"

    if [ "$SHELL" != "$(which zsh)" ]; then
        echo -e "\n${YELLOW}⚠️  Remember to restart your terminal for the shell change to take effect!${NC}"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}🚀 Kubuntu Development Environment Setup${NC}"
    echo "=============================================="

    # Preliminary checks
    check_ubuntu_version

    # Installation steps
    install_system_packages
    install_python
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
    install_tpm
    setup_dotfiles
    setup_shell

    # Completion
    show_completion_message
}

# Run main function
main "$@"
