#!/bin/bash

# Simplified Ubuntu Development Environment Setup Script for WSL
# Designed for Ubuntu 22.04/24.04 on Windows Subsystem for Linux
# Installs: Zsh, Python, .NET SDK, Go, Node.js, Neovim, Claude Code (tools only, configs via stow)
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
        unzip stow \
        jq fzf bat eza htop ncdu tldr \
        tree ripgrep

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

    print_success ".NET development tools installed"
}

install_ohmyzsh() {
    print_header "🎨 Installing Oh My Zsh"

    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh My Zsh already installed"
    else
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed"
    fi

    # Install zsh-autosuggestions
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        echo "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        print_success "zsh-autosuggestions installed"
    else
        print_success "zsh-autosuggestions already installed"
    fi

    # Install zsh-syntax-highlighting
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        echo "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting installed"
    else
        print_success "zsh-syntax-highlighting already installed"
    fi

    print_success "Plugin repositories installed (configure via stow)"
}

install_starship() {
    print_header "⭐ Installing Starship Prompt"

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

install_nvm() {
    print_header "📦 Installing Node Version Manager (nvm)"

    if [ -d "$HOME/.nvm" ]; then
        print_success "nvm already installed"
        return
    fi

    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

    # Load nvm for current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if [ -d "$HOME/.nvm" ]; then
        print_success "nvm installed successfully"

        # Install LTS version of Node.js
        echo "Installing Node.js LTS..."
        nvm install --lts
        nvm use --lts
        print_success "Node.js LTS installed: $(node --version 2>/dev/null || echo 'will be available after shell restart')"
    else
        print_warning "nvm installed but may need shell restart"
    fi
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

    # Add to PATH if not already present
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
    fi

    # Export for current session
    export PATH=$PATH:/usr/local/go/bin
    export PATH=$PATH:$HOME/go/bin

    print_success "Go installed: $(go version)"
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

    echo -e "\n${GREEN}Your simplified Ubuntu WSL development environment is ready!${NC}\n"

    echo "📋 What was installed:"
    echo "  • Essential development tools and packages"
    echo "  • Python 3 with uv package manager $(uv --version 2>/dev/null || echo 'latest')"
    echo "  • .NET SDK $(dotnet --version 2>/dev/null || echo 'latest')"
    echo "  • Go $(go version 2>/dev/null | awk '{print $3}' || echo 'latest')"
    echo "  • Node Version Manager (nvm) with Node.js LTS"
    echo "  • Modern CLI tools: fzf, bat, eza, htop, ncdu, tldr, jq, tree, ripgrep"
    echo "  • Zsh with Oh My Zsh + plugins:"
    echo "    - zsh-autosuggestions (command suggestions)"
    echo "    - zsh-syntax-highlighting (syntax coloring)"
    echo "    - git, z, sudo, extract, colored-man-pages, dotnet"
    echo "  • Starship prompt $(starship --version 2>/dev/null | head -n1 || echo 'latest')"
    echo "  • Claude Code $(claude --version 2>/dev/null || echo 'latest')"
    echo "  • Neovim $(nvim --version 2>/dev/null | head -n1 || echo 'latest')"

    echo -e "\n📌 Next Steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Authenticate Claude Code: claude auth"
    echo "  3. Apply your dotfiles with stow:"
    echo "     cd ~/.dotfiles && stow zsh git neovim tmux claude"
    echo "  4. Launch nvim to auto-install plugins (first run will take a moment)"
    echo "  5. Configure WakaTime in nvim: :WakaTimeApiKey (get key from wakatime.com)"

    echo -e "\n💡 Useful commands:"
    echo "  • claude             - Launch Claude Code CLI"
    echo "  • nvim               - Launch Neovim"
    echo "  • <Space>e           - Toggle file explorer (in nvim)"
    echo "  • <Space>ff          - Find files (in nvim)"
    echo "  • <Space>fg          - Live grep (in nvim)"
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
    echo -e "${BLUE}🚀 Simplified Ubuntu WSL Development Environment Setup${NC}"
    echo "=============================================="

    # Preliminary checks
    check_ubuntu_version

    # Installation steps
    install_system_packages
    install_python
    install_dotnet
    install_go
    install_nvm
    install_ohmyzsh
    install_starship
    install_claude_code
    install_neovim
    setup_shell

    # Completion
    show_completion_message
}

# Run main function
main "$@"
