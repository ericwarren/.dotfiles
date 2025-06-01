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
        python3 python3-pip python3-venv
    
    # Install Neovim 0.10+ from unstable PPA
    echo "Installing Neovim 0.10+..."
    sudo add-apt-repository ppa:neovim-ppa/unstable -y
    sudo apt update
    sudo apt install -y neovim
    
    # Verify Neovim version
    NVIM_VERSION=$(nvim --version | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    NVIM_MAJOR=$(echo $NVIM_VERSION | cut -d. -f1)
    NVIM_MINOR=$(echo $NVIM_VERSION | cut -d. -f2)
    
    if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 10 ]; then
        echo "⚠️  Warning: Neovim version $NVIM_VERSION is older than 0.10"
        echo "   Some features may not work properly"
    else
        echo "✓ Neovim $NVIM_VERSION installed successfully"
    fi
    
    # Install .NET SDK
    if ! command -v dotnet &> /dev/null; then
        echo "Installing .NET SDK..."
        wget https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
        sudo dpkg -i packages-microsoft-prod.deb
        rm packages-microsoft-prod.deb
        sudo apt update
        sudo apt install -y dotnet-sdk-8.0
    fi
    echo ""
    echo "🔧 Installing additional .NET development tools..."

    # Install useful .NET global tools     
    if command -v dotnet &> /dev/null; then
        echo "Installing .NET global tools..."
    
        # Entity Framework tools (for database development)
        dotnet tool install --global dotnet-ef 2>/dev/null || echo "dotnet-ef already installed"
    
        # Tool to check for outdated packages
        dotnet tool install --global dotnet-outdated-tool 2>/dev/null || echo "dotnet-outdated-tool already installed"
    
        # Code formatting tool
        dotnet tool install --global dotnet-format 2>/dev/null || echo "dotnet-format already installed"
    
        # Package vulnerability checker
        dotnet tool install --global dotnet-audit 2>/dev/null || echo "dotnet-audit already installed"
    
        echo "✓ .NET global tools installed"
    else
        echo "⚠️  .NET SDK not found, skipping global tools"
    fi

# Create .NET project templates directory
mkdir -p ~/.dotnet/templates

# Add .NET tools to PATH (they should already be there, but just in case)
if ! echo $PATH | grep -q "$HOME/.dotnet/tools"; then
    echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zshrc
    echo "✓ Added .NET tools to PATH"
fi

echo "✓ Enhanced .NET development tools setup complete"

elif [ "$DISTRO" = "fedora" ]; then
    echo "Installing packages for Fedora 42..."
    
    sudo dnf update -y
    sudo dnf install -y \
        curl wget git zsh gcc gcc-c++ make cmake \
        unzip stow python3 python3-pip
    
    # Install latest Neovim from Fedora repos (should be 0.10+)
    echo "Installing Neovim..."
    sudo dnf install -y neovim
    
    # Verify Neovim version
    NVIM_VERSION=$(nvim --version | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    NVIM_MAJOR=$(echo $NVIM_VERSION | cut -d. -f1)
    NVIM_MINOR=$(echo $NVIM_VERSION | cut -d. -f2)
    
    if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 10 ]; then
        echo "⚠️  Warning: Neovim version $NVIM_VERSION is older than 0.10"
        echo "   You may need to use a third-party repository for newer versions"
    else
        echo "✓ Neovim $NVIM_VERSION installed successfully"
    fi
    
    # Install .NET SDK
    if ! command -v dotnet &> /dev/null; then
        sudo dnf install -y dotnet-sdk-8.0
    fi

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

# Install Node Version Manager (nvm) and latest LTS Node.js
echo ""
echo "📦 Installing Node.js via NVM..."

if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing Node Version Manager (nvm)..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Source nvm for current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    echo "✓ NVM installed"
else
    echo "✓ NVM already installed"
    # Source nvm for current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Install latest LTS Node.js
if ! command -v node &> /dev/null || [ "$(node --version | cut -d'v' -f2 | cut -d'.' -f1)" -lt 20 ]; then
    echo "Installing latest LTS Node.js..."
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*
    echo "✓ Node.js $(node --version) installed (LTS)"
else
    echo "✓ Node.js $(node --version) already installed"
fi

# Verify Node.js version for Copilot compatibility
NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -ge 20 ]; then
    echo "✓ Node.js version is compatible with GitHub Copilot"
else
    echo "⚠️  Node.js version may be too old for Copilot (requires 20+)"
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
npm install -g typescript ts-node yarn pnpm eslint prettier nodemon

echo "Installing Python tools..."
# Handle PEP 668 externally-managed-environment on newer Ubuntu
if [ "$DISTRO" = "ubuntu" ]; then
    # Install available Python tools via apt (system packages)
    sudo apt install -y python3-full python3-pip python3-venv
    
    # Install system packages that are available
    sudo apt install -y python3-pytest python3-flake8 python3-mypy 2>/dev/null || true
    
    # For tools not available as system packages, use a dedicated virtual environment
    if [ ! -d "$HOME/.local/share/python-dev-tools" ]; then
        echo "Creating Python development tools virtual environment..."
        python3 -m venv "$HOME/.local/share/python-dev-tools"
        
        # Install tools in the virtual environment
        "$HOME/.local/share/python-dev-tools/bin/pip" install \
            pipenv poetry black flake8 mypy pytest jupyter ipython
        
        # Create symlinks to make tools available in PATH
        mkdir -p "$HOME/.local/bin"
        for tool in pipenv poetry black flake8 mypy pytest jupyter ipython; do
            if [ -f "$HOME/.local/share/python-dev-tools/bin/$tool" ]; then
                ln -sf "$HOME/.local/share/python-dev-tools/bin/$tool" "$HOME/.local/bin/$tool"
            fi
        done
        
        echo "✓ Python development tools installed in isolated environment"
    else
        echo "✓ Python development tools already installed"
    fi
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
echo "📌 Neovim version: $(nvim --version | head -n1)"

if [ "$STOWED" != true ]; then
    echo "📝 Next: Apply your dotfiles with: stow git zsh neovim"
fi

echo "🐚 Restart your terminal or run: exec zsh"
echo "⚡ Open Neovim and run :checkhealth to verify setup"
echo "⚡ Then run :Copilot setup to configure GitHub Copilot"
echo "🎨 Run 'p10k configure' to set up Powerlevel10k with rainbow theme"