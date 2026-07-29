#!/bin/bash

# Ubuntu Development Environment Setup Script for WSL
# Designed for Ubuntu 22.04/24.04 on Windows Subsystem for Linux
# CLI parity with setup-X1-kubuntu.sh, minus GUI apps (Alacritty, Chrome, Emacs,
# RStudio Desktop, voxd) and host-hardware bits (keyd). RStudio ships as the
# headless Server (browser at localhost:8787) instead of the WSLg Desktop window.
# Installs: Zsh, Python, .NET, Go, Node.js, Rust, Elixir, R + RStudio Server,
# Docker Engine, Neovim, Claude Code, Herdr, Pi, Codex, QEMU/KVM, Azure/Fly/GitHub CLIs
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
        tree ripgrep zoxide \
        imagemagick \
        dbus-user-session keychain

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

install_dotnet() {
    print_header "🔷 Installing .NET SDK"

    if command -v dotnet &> /dev/null; then
        print_success ".NET SDK already installed: $(dotnet --version)"
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

    print_success ".NET development tools installed"
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

install_rust() {
    print_header "🦀 Installing Rust"

    if command -v rustc &> /dev/null; then
        print_success "Rust already installed: $(rustc --version)"
        return
    fi

    echo "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    source "$HOME/.cargo/env"

    rustup component add rust-analyzer rustfmt clippy

    if command -v rustc &> /dev/null; then
        print_success "Rust installed: $(rustc --version)"
        print_success "Cargo installed: $(cargo --version)"
    else
        print_warning "Rust installed but may need PATH update. Restart your shell."
    fi
}

install_elixir() {
    print_header "💧 Installing Elixir & Erlang/OTP"

    if command -v elixir &> /dev/null; then
        print_success "Elixir already installed: $(elixir --version | head -n1)"
        return
    fi

    echo "Adding Erlang Solutions repository..."
    if wget -q --timeout=15 -O /tmp/erlang-solutions.deb https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb 2>/dev/null; then
        sudo dpkg -i /tmp/erlang-solutions.deb
        rm /tmp/erlang-solutions.deb
        sudo apt update
        echo "Installing Erlang/OTP..."
        sudo apt install -y esl-erlang
        echo "Installing Elixir..."
        sudo apt install -y elixir
    else
        echo "Erlang Solutions repo unavailable, falling back to Ubuntu packages..."
        rm -f /tmp/erlang-solutions.deb
        sudo apt update
        echo "Installing Erlang/OTP..."
        sudo apt install -y erlang
        echo "Installing Elixir..."
        sudo apt install -y elixir
    fi

    echo "Installing Hex and rebar3..."
    mix local.hex --force
    mix local.rebar --force

    print_success "Elixir installed: $(elixir --version | head -n1)"
}

install_r() {
    print_header "📊 Installing R (CRAN) and RStudio Server"

    # --- R from CRAN (Ubuntu's bundled r-base lags CRAN by many releases) ---
    if command -v R &> /dev/null; then
        print_success "R already installed: $(R --version | head -n1)"
    else
        echo "Adding CRAN apt repository and signing key..."
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | \
            sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/cran.gpg
        sudo chmod go+r /etc/apt/keyrings/cran.gpg

        # CRAN publishes a cran40 suite per LTS codename (jammy=22.04, noble=24.04,
        # resolute=26.04). Fall back to noble for anything else so an unsupported
        # interim release doesn't 404 the Release file.
        R_DIST=$(lsb_release -cs)
        case "$R_DIST" in
            jammy|noble|resolute)
                # Published by CRAN; use as-is
                ;;
            *)
                print_warning "Using noble (24.04) CRAN suite ($R_DIST not published by CRAN)"
                R_DIST="noble"
                ;;
        esac

        echo "deb [signed-by=/etc/apt/keyrings/cran.gpg] https://cloud.r-project.org/bin/linux/ubuntu ${R_DIST}-cran40/" | \
            sudo tee /etc/apt/sources.list.d/cran.list > /dev/null

        echo "Installing r-base and r-base-dev..."
        sudo apt update
        sudo apt install -y r-base r-base-dev
        print_success "R installed: $(R --version | head -n1)"
    fi

    # --- RStudio Server (browser IDE at http://localhost:8787) ---
    # WSL choice: Desktop would render through WSLg as an X/Wayland window (the ugly
    # border/DPI issues); Server is headless and viewed in the Windows browser, so it
    # looks native. The 'latest' redirect always resolves to the current stable build.
    if dpkg -s rstudio-server &> /dev/null; then
        print_success "RStudio Server already installed: $(dpkg-query -W -f='${Version}' rstudio-server 2>/dev/null || echo installed)"
    else
        echo "Downloading latest RStudio Server .deb..."
        local rstudio_deb="/tmp/rstudio-server-latest-amd64.deb"
        if curl -fSL "https://rstudio.org/download/latest/stable/server/jammy/rstudio-server-latest-amd64.deb" -o "$rstudio_deb"; then
            echo "Installing RStudio Server (apt resolves its dependencies)..."
            sudo apt install -y "$rstudio_deb"
            rm -f "$rstudio_deb"
            print_success "RStudio Server installed: $(dpkg-query -W -f='${Version}' rstudio-server 2>/dev/null || echo 'successfully')"
            print_warning "Open http://localhost:8787 in your Windows browser (log in with your WSL username/password)"
            print_warning "If it isn't running (no systemd): sudo rstudio-server start  —  status: sudo rstudio-server status"
        else
            print_warning "Could not download RStudio Server .deb; install manually from posit.co/download/rstudio-server"
        fi
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

install_herdr() {
    print_header "🐐 Installing Herdr (agent multiplexer)"

    export PATH="$HOME/.local/bin:$PATH"

    if command -v herdr &> /dev/null; then
        print_success "Herdr already installed: $(herdr --version 2>/dev/null | head -n1 || echo 'installed')"
        return
    fi

    echo "Installing Herdr (single Rust binary; no sudo)..."
    curl -fsSL https://herdr.dev/install.sh | sh

    if command -v herdr &> /dev/null; then
        print_success "Herdr installed: $(herdr --version 2>/dev/null | head -n1 || echo 'successfully')"
    else
        print_warning "Herdr installed but may need PATH update. Restart your shell."
    fi
}

install_pi() {
    print_header "🥧 Installing Pi (coding agent)"

    export PATH="$HOME/.local/bin:$PATH"

    if command -v pi &> /dev/null; then
        print_success "Pi already installed: $(pi --version 2>/dev/null | head -n1 || echo 'installed')"
        return
    fi

    echo "Installing Pi (single binary; no sudo)..."
    curl -fsSL https://pi.dev/install.sh | sh

    if command -v pi &> /dev/null; then
        print_success "Pi installed: $(pi --version 2>/dev/null | head -n1 || echo 'successfully')"
    else
        print_warning "Pi installed but may need PATH update. Restart your shell."
    fi
}

install_codex() {
    print_header "🧠 Installing OpenAI Codex CLI"

    # Load nvm/Node into this session so the global npm prefix resolves (install_nodejs
    # ran earlier in main(), but re-sourcing keeps this function robust standalone).
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if command -v codex &> /dev/null; then
        print_success "Codex CLI already installed: $(codex --version 2>/dev/null | head -n1 || echo 'installed')"
        return
    fi

    if ! command -v npm &> /dev/null; then
        print_warning "npm not found; skipping Codex (needs install_nodejs first)"
        return
    fi

    # Codex ships as a Rust binary wrapped in the @openai/codex npm package. Installing
    # globally via the nvm-managed Node keeps it sudo-free and self-updating with npm,
    # matching the other global CLIs (typescript, prettier, ...).
    echo "Installing @openai/codex globally via npm..."
    npm install -g @openai/codex

    if command -v codex &> /dev/null; then
        print_success "Codex CLI installed: $(codex --version 2>/dev/null | head -n1 || echo 'successfully')"
    else
        print_warning "Codex installed but may need PATH update. Restart your shell."
    fi
    print_warning "Authenticate on first run: 'codex' then sign in (ChatGPT account or OPENAI_API_KEY)"
}

install_neovim() {
    print_header "📝 Installing Neovim"

    sudo apt install -y ripgrep fd-find

    # Install Neovim from official GitHub stable release
    echo "Downloading Neovim stable release..."
    local nvim_archive="/tmp/nvim-linux-x86_64.tar.gz"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" -o "$nvim_archive"
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo tar -C /opt -xzf "$nvim_archive"
    rm -f "$nvim_archive"
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

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
                echo '# Go paths added by setup-WSL-ubuntu.sh'
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

install_docker() {
    print_header "🐳 Installing Docker Engine"

    if command -v docker &> /dev/null; then
        print_success "Docker already installed: $(docker --version)"
        return
    fi

    # WSL note: this installs Docker Engine *inside* WSL (an alternative to Docker
    # Desktop's WSL integration). The daemon needs systemd as PID 1 — recent WSL
    # enables it by default; if not, add "[boot]\nsystemd=true" to /etc/wsl.conf and
    # run 'wsl --shutdown' from Windows. Don't run this AND Docker Desktop integration.
    echo "Removing old Docker installations..."
    sudo apt remove -y docker.io docker-doc docker-compose podman-docker containerd runc 2>/dev/null || true

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

    echo "Adding $USER to docker group..."
    sudo usermod -aG docker "$USER"

    # Only drive systemd if it's actually PID 1 (WSL may boot without it).
    if [ "$(ps -p 1 -o comm= 2>/dev/null)" = "systemd" ]; then
        echo "Enabling Docker service..."
        sudo systemctl enable --now docker || print_warning "Could not enable/start docker via systemd"
    else
        print_warning "systemd is not PID 1 in this WSL distro."
        print_warning "  Enable it: add '[boot]\\nsystemd=true' to /etc/wsl.conf, then 'wsl --shutdown' from Windows"
        print_warning "  Then start the daemon: sudo systemctl enable --now docker  (or: sudo service docker start)"
    fi

    print_success "Docker installed: $(docker --version)"
    print_warning "Log out/in (or 'wsl --shutdown') for docker group membership to take effect"
}

install_gondolin_sandbox() {
    print_header "📦 Installing Gondolin sandbox prerequisites (QEMU + KVM)"

    # Host prerequisites for running Pi tool calls inside a Gondolin micro-VM.
    # Installs only the QEMU/KVM plumbing; the pi-gondolin extension itself is
    # registered manually in ~/.pi/agent/settings.json (kept out of this script).
    if command -v qemu-system-x86_64 &> /dev/null; then
        print_success "QEMU already installed: $(qemu-system-x86_64 --version | head -n1)"
    else
        echo "Installing qemu-system-x86..."
        sudo apt install -y qemu-system-x86
        print_success "QEMU installed: $(qemu-system-x86_64 --version | head -n1)"
    fi

    # KVM acceleration inside WSL2 needs nested virtualization: /dev/kvm only appears
    # when the Windows host exposes it (Hyper-V nested virt). Warn (don't fail) if
    # missing — Gondolin would otherwise fall back to slow pure emulation.
    if [ -e /dev/kvm ]; then
        print_success "/dev/kvm present (KVM acceleration available)"
        if id -nG "$USER" | tr ' ' '\n' | grep -qx kvm; then
            print_success "$USER already in 'kvm' group (KVM access without sudo)"
        else
            echo "Adding $USER to 'kvm' group for /dev/kvm access..."
            sudo usermod -aG kvm "$USER"
            print_warning "Log out/in (or 'wsl --shutdown') for 'kvm' group membership to take effect"
        fi
    else
        print_warning "/dev/kvm not present — under WSL enable nested virtualization on the host"
        print_warning "  (Set-VMProcessor -VMName <distro> -ExposeVirtualizationExtensions \$true), else Gondolin runs emulated"
    fi

    print_success "Gondolin sandbox host prerequisites ready"
    print_warning "Register the extension manually: clone pi-gondolin and add it to"
    print_warning "  ~/.pi/agent/settings.json  \"extensions\": [\"~/.pi/agent/extensions/gondolin\"]"
}

install_flyctl() {
    print_header "🎈 Installing Fly.io CLI (flyctl)"

    # flyctl installs to ~/.fly/bin (no sudo). The stowed zsh config already puts that
    # on PATH, so export it here too for the rest of this run.
    export FLYCTL_INSTALL="$HOME/.fly"
    export PATH="$FLYCTL_INSTALL/bin:$PATH"

    if command -v flyctl &> /dev/null; then
        print_success "flyctl already installed: $(flyctl version 2>/dev/null | head -n1 || echo 'installed')"
        return
    fi

    # Piped into sh the installer stays non-interactive, so it will NOT append a
    # machine-specific PATH block to ~/.zshrc — PATH is handled by the stowed zsh
    # package instead, keeping shell config portable across machines.
    echo "Installing flyctl..."
    curl -fsSL https://fly.io/install.sh | sh

    if command -v flyctl &> /dev/null; then
        print_success "flyctl installed: $(flyctl version 2>/dev/null | head -n1 || echo 'successfully')"
    else
        print_warning "flyctl installed but may need PATH update. Restart your shell."
    fi
    print_warning "Authenticate manually: 'fly auth signup' (new account) or 'fly auth login'"
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

setup_shell() {
    print_header "🐚 Setting Up Zsh Shell with Oh My Zsh and Starship"

    # Install Oh My Zsh
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_success "Oh My Zsh already installed"
    else
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed"
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

    echo -e "\n${GREEN}Your simplified Ubuntu WSL development environment is ready!${NC}\n"

    echo "📋 What was installed:"
    echo "  • Essential development tools and packages"
    echo "  • Python 3 with uv package manager $(uv --version 2>/dev/null || echo 'latest')"
    DOTNET_SUMMARY=$(dotnet --list-sdks 2>/dev/null | head -n5 | paste -sd ', ' -)
    echo "  • .NET SDKs ${DOTNET_SUMMARY:-installed}"
    echo "  • Go $(go version 2>/dev/null | awk '{print $3}' || echo 'latest')"
    echo "  • Node Version Manager (nvm) with Node.js LTS + Corepack + global tools"
    echo "  • Rust $(rustc --version 2>/dev/null || echo 'latest') with cargo, clippy, rustfmt, rust-analyzer"
    echo "  • R $(R --version 2>/dev/null | head -n1 | awk '{print $3}' || echo 'latest') (CRAN) + RStudio Server $(dpkg-query -W -f='${Version}' rstudio-server 2>/dev/null || echo 'latest') (browser: localhost:8787)"
    echo "  • Elixir $(elixir --version 2>/dev/null | head -n1 || echo 'latest') with Erlang/OTP, Hex, rebar3"
    echo "  • Docker Engine $(docker --version 2>/dev/null || echo 'latest')"
    echo "  • Modern CLI tools: fzf, bat, eza, htop, ncdu, tldr, jq, tree, ripgrep, zoxide"
    echo "  • Zsh with Oh My Zsh + plugins:"
    echo "    - zsh-autosuggestions (command suggestions)"
    echo "    - zsh-syntax-highlighting (syntax coloring)"
    echo "    - git, z, sudo, extract, colored-man-pages, dotnet"
    echo "  • Starship prompt $(starship --version 2>/dev/null | head -n1 || echo 'latest')"
    echo "  • Claude Code $(claude --version 2>/dev/null || echo 'latest')"
    echo "  • Herdr $(herdr --version 2>/dev/null | head -n1 || echo 'latest') (agent multiplexer for coding agents)"
    echo "  • Pi $(pi --version 2>/dev/null | head -n1 || echo 'latest') (minimal terminal coding agent)"
    echo "  • OpenAI Codex CLI $(codex --version 2>/dev/null | head -n1 || echo 'latest')"
    echo "  • Gondolin sandbox prereqs: QEMU $(qemu-system-x86_64 --version 2>/dev/null | head -n1 | awk '{print $4}' || echo 'latest') + kvm group (needs WSL nested virt)"
    echo "  • Azure CLI $(az version --output tsv --query '\"azure-cli\"' 2>/dev/null || echo 'latest')"
    echo "  • Fly.io CLI $(flyctl version 2>/dev/null | head -n1 | awk '{print $2}' || echo 'latest')"
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
    echo "  • herdr              - Agent multiplexer (tmux for coding agents)"
    echo "  • pi                 - Minimal terminal coding agent (/login then /model)"
    echo "  • codex              - OpenAI Codex CLI (sign in with ChatGPT or OPENAI_API_KEY)"
    echo "  • nvim               - Launch Neovim"
    echo "  • <Space>e           - Toggle file explorer (in nvim)"
    echo "  • <Space>ff          - Find files (in nvim)"
    echo "  • <Space>fg          - Live grep (in nvim)"
    echo "  • R                  - R interactive console (Rscript for scripts)"
    echo "  • rstudio-server start - Start RStudio Server, then open http://localhost:8787"
    echo "  • az login           - Login to Azure"
    echo "  • az --version       - Check Azure CLI version"
    echo "  • fly auth login     - Authenticate with Fly.io (auth signup for a new account)"
    echo "  • fly launch         - Deploy an app to Fly.io from the current directory"
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
    echo -e "${BLUE}🚀 Simplified Ubuntu WSL Development Environment Setup${NC}"
    echo "=============================================="

    # Preliminary checks
    check_ubuntu_version

    # Installation steps
    install_system_packages
    install_python
    install_dotnet
    install_docker
    install_go
    install_nodejs
    install_rust
    install_r
    install_elixir
    install_claude_code
    install_herdr
    install_pi
    install_codex
    install_gondolin_sandbox
    install_azure_cli
    install_flyctl
    install_github_cli
    install_tpm
    install_neovim
    setup_shell

    # Completion
    show_completion_message
}

# Run main function
main "$@"
