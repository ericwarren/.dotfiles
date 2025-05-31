#!/bin/bash

# Linux Development Environment Setup Script
# Supports Ubuntu 24.04 and Fedora 42 on WSL
# Usage: ./setup.sh

set -e

echo "🚀 Starting Linux Development Environment Setup"
echo "=============================================="

# Check if running in WSL
if grep -q Microsoft /proc/version 2>/dev/null; then
    echo "✓ Running in WSL environment"
else
    echo "⚠️  Not running in WSL - some features may not work as expected"
fi

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    echo "✓ Detected distribution: $DISTRO"
else
    echo "❌ Cannot detect distribution"
    exit 1
fi

# Update system and install packages based on distribution
echo ""
echo "📦 Installing packages..."

if [ "$DISTRO" = "ubuntu" ]; then
    echo "Installing packages for Ubuntu 24.04..."
    
    sudo apt update
    sudo apt install -y \
        curl wget git zsh build-essential \
        software-properties-common apt-transport-https \
        ca-certificates gnupg lsb-release unzip stow \
        python3 python3-pip python3-venv nodejs npm
    
    # Install Neovim (latest stable)
    sudo add-apt-repository ppa:neovim-ppa/stable -y
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
    echo "Installing packages for Fedora 42..."
    
    sudo dnf update -y
    sudo dnf install -y \
        curl wget git zsh gcc gcc-c++ make cmake \
        unzip stow python3 python3-pip nodejs npm \
        neovim rust cargo dotnet-sdk-8.0

else
    echo "❌ Unsupported distribution: $DISTRO"
    echo "This script supports Ubuntu 24.04 and Fedora 42"
    exit 1
fi

# Install Rust (if not already installed)
if ! command -v rustc &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source ~/.cargo/env
fi

echo "✓ System packages installed"

# Install Oh My Zsh and Powerlevel10k
echo ""
echo "🐚 Setting up Zsh with Powerlevel10k..."

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    
    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        echo "Backing up existing .zshrc to .zshrc.backup"
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
    fi
    
    # Install Oh My Zsh without creating .zshrc
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    
    # Remove the default .zshrc created by Oh My Zsh if it exists
    if [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
        echo "Removing default .zshrc (will be managed by dotfiles)"
        rm "$HOME/.zshrc"
    fi
    
    echo "✓ Oh My Zsh installed"
else
    echo "✓ Oh My Zsh already installed"
fi

# Install Powerlevel10k theme
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
    echo "✓ Powerlevel10k installed"
else
    echo "✓ Powerlevel10k already installed"
fi

# Install zsh plugins
echo "Installing zsh plugins..."
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi

if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

echo "✓ Zsh plugins installed"

# Install Node.js tools
echo ""
echo "📦 Installing development tools..."

echo "Installing Node.js tools..."
sudo npm install -g typescript ts-node yarn pnpm eslint prettier nodemon

echo "Installing Python tools..."
# Handle PEP 668 externally-managed-environment on newer Ubuntu
if [ "$DISTRO" = "ubuntu" ]; then
    # Install pipx for isolated Python applications
    sudo apt install -y python3-pipx
    
    # Install Python development tools via pipx (isolated environments)
    pipx install pipenv
    pipx install poetry
    pipx install black
    pipx install flake8
    pipx install mypy
    pipx install pytest
    
    # Install jupyter and ipython via apt (system packages)
    sudo apt install -y python3-jupyter python3-ipython
    
    # Ensure pipx bin directory is in PATH
    pipx ensurepath
else
    # Fedora doesn't have this restriction
    pip3 install --user pipenv poetry black flake8 mypy pytest jupyter ipython
fi

# Setup Rust tools
if command -v rustc &> /dev/null; then
    echo "Setting up Rust tools..."
    rustup component add rustfmt clippy rust-analyzer
    cargo install cargo-watch cargo-edit
fi

echo "✓ Development tools installed"

# Setup directories
echo ""
echo "📁 Creating development directories..."

mkdir -p ~/dev/{projects,sandbox,learning}
mkdir -p ~/dev/projects/{csharp,python,javascript,rust}
mkdir -p ~/.config/nvim/lua

echo "✓ Development directories created"

# Apply dotfiles with Stow (optional)
echo ""
echo "🔗 Checking for dotfiles..."

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
stow_packages=()

# Check for common dotfile packages - ADD NEW PACKAGES HERE
for pkg in git zsh neovim; do
    if [ -d "$script_dir/$pkg" ]; then
        stow_packages+=("$pkg")
    fi
done

if [ ${#stow_packages[@]} -eq 0 ]; then
    echo "⚠️  No dotfile packages found in $script_dir"
    echo "Expected directories: git/, zsh/, neovim/"
    echo "You can run Stow manually later: stow git zsh neovim"
else
    echo "Found dotfile packages: ${stow_packages[*]}"
    
    # Ask user if they want to apply dotfiles now
    if [ -t 0 ]; then  # Interactive terminal
        read -p "Apply dotfiles with Stow now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$script_dir"
            for pkg in "${stow_packages[@]}"; do
                echo "Stowing $pkg..."
                if stow "$pkg" 2>/dev/null; then
                    echo "✓ Successfully stowed $pkg"
                else
                    echo "⚠️  Failed to stow $pkg - may have conflicts"
                    echo "Check manually: stow -v $pkg"
                fi
            done
            echo "✓ Dotfiles applied with Stow"
            STOWED=true
        else
            echo "Skipping Stow step"
            STOWED=false
        fi
    else
        echo "Non-interactive mode - skipping Stow"
        STOWED=false
    fi
fi

# Change default shell to zsh
echo ""
echo "🐚 Setting up shell..."

if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to zsh..."
    chsh -s $(which zsh)
    echo "✓ Shell changed to zsh"
else
    echo "✓ Default shell is already zsh"
fi

# Final instructions
echo ""
echo "🎉 Setup completed successfully!"
echo ""

if [ "$STOWED" != true ]; then
    echo "📝 Next: Apply your dotfiles with: stow git zsh neovim"
fi

echo "🐚 Restart your terminal or run: exec zsh"
echo "⚡ Open Neovim and run :Copilot setup"
echo "🎨 Run 'p10k configure' to set up Powerlevel10k with rainbow theme"