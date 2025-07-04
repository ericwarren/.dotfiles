#!/bin/bash

# Simplified WSL Development Environment Setup Script
# Installs: neovim, python, dotnet, nvm/node, claude code, git, stow
# Usage: ./setup-WSL.sh

set -e

echo "🚀 Starting WSL Development Environment Setup"
echo "============================================="

# Check if running in WSL
if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "❌ Not running in WSL - this script is designed for WSL environments"
    exit 1
fi

echo "✅ Running in WSL environment"

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    echo "📦 Detected distribution: $DISTRO"
else
    echo "❌ Cannot detect distribution"
    exit 1
fi

# Update system and install essential packages
echo ""
echo "📦 Installing essential packages..."

if [ "$DISTRO" = "ubuntu" ]; then
    sudo apt update
    sudo apt install -y \
        curl wget git stow build-essential \
        software-properties-common apt-transport-https \
        ca-certificates unzip zsh \
        python3 python3-pip python3-venv

    # Install Neovim 0.10+
    echo "Installing Neovim 0.10+..."
    sudo add-apt-repository ppa:neovim-ppa/unstable -y
    sudo apt update
    sudo apt install -y neovim

    # Install .NET SDK
    if ! command -v dotnet &> /dev/null; then
        echo "Installing .NET SDK..."
        wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
        sudo dpkg -i packages-microsoft-prod.deb
        rm packages-microsoft-prod.deb
        sudo apt update
        sudo apt install -y dotnet-sdk-8.0
    fi

elif [ "$DISTRO" = "fedora" ]; then
    sudo dnf update -y
    sudo dnf install -y \
        curl wget git stow gcc gcc-c++ make cmake \
        unzip neovim python3 python3-pip dotnet-sdk-8.0 zsh

else
    echo "❌ Unsupported distribution: $DISTRO"
    echo "This script supports Ubuntu and Fedora"
    exit 1
fi

# Install .NET global tools
echo ""
echo "🔧 Installing .NET development tools..."

if command -v dotnet &> /dev/null; then
    echo "Installing .NET global tools..."
    dotnet tool install --global dotnet-ef 2>/dev/null || echo "dotnet-ef already installed"
    dotnet tool install --global dotnet-outdated-tool 2>/dev/null || echo "dotnet-outdated-tool already installed"
    dotnet tool install --global dotnet-format 2>/dev/null || echo "dotnet-format already installed"
    echo "✅ .NET global tools installed"
else
    echo "⚠️ .NET SDK not found, skipping global tools"
fi

# Install Node Version Manager (nvm) and Node.js
echo ""
echo "📦 Installing Node.js via NVM..."

if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    echo "✅ NVM installed"
else
    echo "✅ NVM already installed"
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Install latest LTS Node.js
echo "Installing latest LTS Node.js..."
nvm install --lts
nvm use --lts
nvm alias default lts/*
echo "✅ Node.js $(node --version) installed"

# Setup Zsh with Oh My Zsh and Starship
echo ""
echo "🐚 Setting Up Zsh with Oh My Zsh and Starship"

# Install Oh My Zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."

    # Backup existing .zshrc
    if [ -f "$HOME/.zshrc" ]; then
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
        echo "✅ Backed up existing .zshrc"
    fi

    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    echo "✅ Oh My Zsh installed"
else
    echo "✅ Oh My Zsh already installed"
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

echo "✅ Zsh plugins installed"

# Check if starship is already installed
if command -v starship &> /dev/null; then
    echo "✅ Starship already installed: $(starship --version)"
else
    echo "Installing Starship prompt..."

    # Install starship using the official installer
    if curl -sS https://starship.rs/install.sh | sh; then
        echo "✅ Starship installed successfully"
    else
        echo "❌ Failed to install Starship"
        exit 1
    fi

    # Verify installation
    if command -v starship &> /dev/null; then
        STARSHIP_VERSION=$(starship --version | head -n1)
        echo "✅ Starship installed: $STARSHIP_VERSION"
    else
        echo "❌ Starship installation verification failed"
        exit 1
    fi
fi

# Configure default shell
echo ""
echo "🐚 Configuring Default Shell"

if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
    echo "✅ Default shell changed to zsh"
    echo "⚠️  You'll need to restart your terminal or logout/login for this to take effect"
else
    echo "✅ Default shell is already zsh"
fi

# Install Claude Code
echo ""
echo "🤖 Installing Claude Code..."

if ! command -v claude &> /dev/null; then
    echo "Installing Claude Code via npm..."
    npm install -g @anthropic/claude-code
    echo "✅ Claude Code installed"
else
    echo "✅ Claude Code already installed"
fi

# Apply dotfiles with Stow
echo ""
echo "🔧 Checking for dotfiles..."

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stow_packages=()

# Check for dotfile packages
for pkg in git neovim zsh; do
    if [ -d "$script_dir/$pkg" ]; then
        stow_packages+=("$pkg")
    fi
done

if [ ${#stow_packages[@]} -eq 0 ]; then
    echo "⚠️  No dotfile packages found in $script_dir"
    echo "Expected directories: git/, neovim/, zsh/"
    echo "You can run Stow manually later: stow git neovim zsh"
else
    echo "Found dotfile packages: ${stow_packages[*]}"
    
    if [ -t 0 ]; then
        read -p "Apply dotfiles with Stow now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$script_dir"
            for pkg in "${stow_packages[@]}"; do
                echo "Stowing $pkg..."
                if stow "$pkg" 2>/dev/null; then
                    echo "✅ Successfully stowed $pkg"
                else
                    echo "⚠️  Failed to stow $pkg - may have conflicts"
                fi
            done
            echo "✅ Dotfiles applied with Stow"
        fi
    fi
fi

# Final instructions
echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Installed:"
echo "   • Neovim: $(nvim --version | head -n1)"
echo "   • Python: $(python3 --version)"
echo "   • .NET: $(dotnet --version 2>/dev/null || echo 'Not found')"
echo "   • Node.js: $(node --version)"
echo "   • Claude Code: $(claude --version 2>/dev/null || echo 'Not found')"
echo "   • Zsh with Oh My Zsh and Starship prompt"
echo "   • Git and GNU Stow for config management"
echo ""
echo "📋 Next steps:"
echo "   • Use 'stow git neovim zsh' to apply dotfiles"
echo "   • Restart your terminal or run: exec zsh"
echo "   • Open Neovim and run :checkhealth to verify setup"
echo ""
echo "✅ Your WSL development environment is ready!"