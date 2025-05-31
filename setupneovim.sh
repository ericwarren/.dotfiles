#!/bin/bash
# Neovim Development Environment Setup Function for Nix Package Manager
# Designed to be sourced into a master script

setup_neovim_dev() {
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local NC='\033[0m'

    print_status() { echo -e "${GREEN}[NVIM]${NC} $1"; }
    print_warning() { echo -e "${YELLOW}[NVIM]${NC} $1"; }
    print_error() { echo -e "${RED}[NVIM]${NC} $1"; }

    print_status "Setting up Neovim development environment with Nix..."

    # Install packages via Nix
    install_nix_packages() {
        print_status "Installing packages via Nix..."
        
        local packages=(
            # Core development tools
            "neovim"
            "git"
            "curl"
            "wget"
            "unzip"
            "tree"
            "ripgrep"
            "fd"
            
            # Language runtimes
            "nodejs_20"
            "python3"
            "python3Packages.pip"
            "dotnet-sdk_8"
            
            # Development tools
            "docker"
            "docker-compose"
            
            # Shell tools
            "shfmt"
            "shellcheck"
        )
        
        print_status "Installing: ${packages[*]}"
        nix-env -iA ${packages[@]/#/nixpkgs.}
        
        # Alternative: if using flakes or home-manager, user can add these to their config
        print_warning "Alternative: Add these packages to your nix configuration:"
        echo "  environment.systemPackages = with pkgs; ["
        printf "    %s\n" "${packages[@]}" | sed 's/^/    /'
        echo "  ];"
    }

    # Install Node.js based LSP servers and tools
    install_node_tools() {
        print_status "Installing Node.js based LSP servers and formatters..."
        
        # Check if npm is available
        if ! command -v npm &> /dev/null; then
            print_error "npm not found. Please ensure nodejs is installed via Nix."
            return 1
        fi
        
        local npm_packages=(
            "typescript"
            "typescript-language-server"
            "prettier"
            "bash-language-server"
            "dockerfile-language-server-nodejs"
            "docker-compose-language-service"
            "vscode-langservers-extracted"  # HTML, CSS, JSON, ESLint
            "@fsouza/prettierd"            # Faster prettier
        )
        
        print_status "Installing npm packages globally..."
        npm install -g "${npm_packages[@]}"
    }

    # Install Python tools
    install_python_tools() {
        print_status "Installing Python development tools..."
        
        if ! command -v pip3 &> /dev/null; then
            print_error "pip3 not found. Please ensure python3 and pip are installed via Nix."
            return 1
        fi
        
        # Install Python LSP and formatters
        pip3 install --user \
            black \
            isort \
            flake8 \
            mypy \
            pyright \
            python-lsp-server[all] \
            debugpy
    }

    # Install .NET tools
    install_dotnet_tools() {
        print_status "Installing .NET development tools..."
        
        if ! command -v dotnet &> /dev/null; then
            print_warning ".NET SDK not found. Some C# features may not work."
            return 0
        fi
        
        # Install .NET global tools
        dotnet tool install --global csharpier
        dotnet tool install --global dotnet-ef  # Entity Framework tools
    }

    # Setup directories only (no config file creation)
    setup_nvim_directories
    setup_directories() {
        print_status "Setting up Neovim directories..."
        mkdir -p "$HOME/.local/share/nvim"
    }

    # Setup additional directories
    setup_directories() {
        print_status "Setting up additional directories..."
        mkdir -p "$HOME/.vim/undodir"
    }

    # Verify installation
    verify_installation() {
        print_status "Verifying installation..."
        
        local tools=("nvim" "node" "python3" "dotnet" "git" "rg")
        local missing_tools=()
        
        for tool in "${tools[@]}"; do
            if command -v "$tool" &> /dev/null; then
                print_status "✓ $tool installed"
            else
                missing_tools+=("$tool")
                print_warning "✗ $tool not found"
            fi
        done
        
        if [ ${#missing_tools[@]} -eq 0 ]; then
            print_status "All tools installed successfully!"
        else
            print_warning "Missing tools: ${missing_tools[*]}"
            print_warning "Install them via: nix-env -iA nixpkgs.<package-name>"
        fi
    }

    # Print post-installation instructions
    post_install_instructions() {
        echo ""
        print_status "🎉 Neovim setup completed!"
        echo ""
        echo "📋 Next steps:"
        echo "1. Use stow to symlink your nvim config: stow nvim"
        echo "2. Start Neovim: nvim"
        echo "3. Wait for plugins to install automatically"
        echo "4. Run :checkhealth to verify everything works"
        echo "5. Run :Mason to manage LSP servers"
        echo ""
        echo "🔧 Key bindings:"
        echo "  <Space> - Leader key"
        echo "  <Leader>ff - Find files"
        echo "  <Leader>fg - Live grep"
        echo "  <Leader>e - Toggle file explorer"
        echo "  gd - Go to definition"
        echo "  K - Hover documentation"
        echo "  <Leader>fmt - Format code"
        echo "  <Leader>y - Copy to Windows clipboard (WSL)"
        echo ""
        echo "💡 WSL Tips:"
        echo "- Clipboard integration is configured for Windows"
        echo "- Use Windows Terminal or VSCode terminal for best experience"
        echo "- Docker commands will work if Docker Desktop is running"
    }

    # Main execution
    if ! command -v nix-env &> /dev/null; then
        print_error "Nix package manager not found. Please install Nix first."
        return 1
    fi

    install_nix_packages
    install_node_tools
    install_python_tools
    install_dotnet_tools
    setup_nvim_directories
    verify_installation
    post_install_instructions
}

# Note: This function can be called from your master script with:
# setup_neovim_dev