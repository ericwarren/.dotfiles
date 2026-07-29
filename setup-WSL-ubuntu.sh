#!/bin/bash

# Ubuntu Development Environment Setup Script for WSL
# Designed for Ubuntu 22.04/24.04 on Windows Subsystem for Linux
# CLI parity with setup-X1-kubuntu.sh, minus GUI apps (Alacritty, Chrome, voxd)
# and host-hardware bits (keyd). Docker (use Docker Desktop's WSL integration
# on Windows) and R/RStudio (installed on the Windows side) are intentionally omitted.
# Installs: Zsh, Python, .NET, Node.js, Rust, Neovim, Doom Emacs, Claude Code, Herdr,
# Pi, Codex, QEMU/KVM, Azure/Fly/GitHub CLIs
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
        jq fzf bat eza htop ncdu \
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
    print_header "📗 Installing Node.js via fnm"

    export PATH="$HOME/.local/bin:$PATH"

    # Install fnm (Fast Node Manager) if not present
    if command -v fnm &> /dev/null; then
        print_success "fnm already installed: $(fnm --version)"
    else
        echo "Installing fnm (Fast Node Manager)..."
        curl -fsSL https://github.com/Schniz/fnm/releases/latest/download/fnm-linux.zip -o /tmp/fnm.zip
        unzip -o /tmp/fnm.zip -d "$HOME/.local/bin"
        chmod +x "$HOME/.local/bin/fnm"
        rm -f /tmp/fnm.zip
        print_success "fnm installed: $(fnm --version)"
    fi

    # Load fnm into the current session (.zshrc already runs 'fnm env --use-on-cd' on login)
    eval "$(fnm env)"

    # Install latest LTS Node.js and make it the default
    echo "Installing latest LTS Node.js..."
    fnm install --lts
    fnm default lts-latest
    fnm use lts-latest

    NODE_VERSION=$(node --version)
    print_success "Node.js $NODE_VERSION installed (via fnm)"

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

    # Load fnm/Node into this session so the global npm prefix resolves (install_nodejs
    # ran earlier in main(), but re-eval keeps this function robust if run standalone).
    export PATH="$HOME/.local/bin:$PATH"
    if command -v fnm &> /dev/null; then
        eval "$(fnm env)" 2>/dev/null || true
    fi

    if command -v codex &> /dev/null; then
        print_success "Codex CLI already installed: $(codex --version 2>/dev/null | head -n1 || echo 'installed')"
        return
    fi

    if ! command -v npm &> /dev/null; then
        print_warning "npm not found; skipping Codex (needs install_nodejs first)"
        return
    fi

    # Codex ships as a Rust binary wrapped in the @openai/codex npm package. Installing
    # globally via the fnm-managed Node keeps it sudo-free and self-updating with npm,
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

install_doom_emacs() {
    print_header "😈 Installing Doom Emacs"

    # Emacs itself — Doom runs on top of it. Prefer the pure-GTK build: WSLg gives WSL2
    # a Wayland display, so plain 'emacs' can open a real GUI frame without needing
    # XWayland/XAUTHORITY. pgtk isn't published for every Ubuntu release, so fall back
    # to emacs-gtk and finally emacs-nox (terminal-only) — Doom runs on all three, and
    # 'emacs -nw' works regardless of which one landed.
    if command -v emacs &> /dev/null; then
        print_success "Emacs already installed: $(emacs --version | head -n1)"
    else
        local emacs_pkg=""
        for pkg in emacs-pgtk emacs-gtk emacs-nox; do
            echo "Installing $pkg..."
            if sudo apt install -y "$pkg"; then
                emacs_pkg="$pkg"
                break
            fi
            print_warning "$pkg unavailable in this release; trying the next Emacs build"
        done

        if [ -n "$emacs_pkg" ]; then
            print_success "Emacs installed ($emacs_pkg): $(emacs --version | head -n1)"
        else
            print_error "No Emacs package could be installed; skipping Doom"
            return
        fi
    fi

    # The Doom framework lives at ~/.config/emacs (cloned here); the private config
    # (~/.config/doom) comes from the stowed 'emacs' package. This script doesn't stow,
    # so the doom install step is gated on that config already existing.
    #
    # No emacs --daemon here (unlike setup-X1-kubuntu.sh): WSL2 shuts the VM down when
    # the last session closes, so a boot-time daemon mostly buys a resident 200-400MB
    # rather than a warm editor. Just run 'emacs -nw'; the stowed unit is available if
    # that ever changes ('systemctl --user enable --now emacs').
    if [ -d "$HOME/.config/emacs/.git" ]; then
        print_success "Doom Emacs framework already cloned (~/.config/emacs)"
    else
        echo "Cloning Doom Emacs framework..."
        git clone --depth 1 https://github.com/doomemacs/doomemacs "$HOME/.config/emacs"
        print_success "Doom Emacs framework cloned"
    fi

    if [ -f "$HOME/.config/doom/init.el" ]; then
        echo "Installing Doom packages (doom install; can take a few minutes)..."
        if "$HOME/.config/emacs/bin/doom" install --force >/dev/null 2>&1; then
            print_success "Doom packages installed"
        else
            print_warning "doom install had issues; re-run '~/.config/emacs/bin/doom install' manually"
        fi
        print_success "Doom ready — launch with 'emacs -nw' (no daemon on WSL by design)"
    else
        print_warning "Doom config (~/.config/doom) not found — stow the 'emacs' package, then run:"
        print_warning "  ~/.config/emacs/bin/doom install"
    fi
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

    # Microsoft only publishes azure-cli packages for Ubuntu LTS releases
    # (jammy = 22.04, noble = 24.04). Anything else — interim releases and
    # newer LTSes not yet supported (e.g. resolute/26.04) — 404s on the repo's
    # Release file, so fall back to the latest supported LTS (noble). Allowlist,
    # not a blocklist, so future unsupported codenames are handled automatically.
    case "$AZ_DIST" in
        jammy|noble)
            # Natively supported; use as-is
            ;;
        *)
            print_warning "Using noble (24.04) repository for Azure CLI ($AZ_DIST not supported by Microsoft)"
            AZ_DIST="noble"
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
    echo "  • fnm (Fast Node Manager) with Node.js LTS $(node --version 2>/dev/null || echo '') + Corepack + global tools"
    echo "  • Rust $(rustc --version 2>/dev/null || echo 'latest') with cargo, clippy, rustfmt, rust-analyzer"
    echo "  • Modern CLI tools: fzf, bat, eza, htop, ncdu, jq, tree, ripgrep, zoxide"
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
    echo "  • Doom Emacs on $(emacs --version 2>/dev/null | head -n1 || echo 'Emacs')"

    echo -e "\n📌 Next Steps:"
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Authenticate Claude Code: claude auth"
    echo "  3. Apply your dotfiles with stow:"
    echo "     cd ~/.dotfiles && stow zsh git neovim tmux emacs claude"
    echo "  4. Launch nvim to auto-install plugins (first run will take a moment)"
    echo "  5. If the 'emacs' package wasn't stowed before this ran, finish Doom setup:"
    echo "     ~/.config/emacs/bin/doom install"

    echo -e "\n💡 Useful commands:"
    echo "  • claude             - Launch Claude Code CLI"
    echo "  • herdr              - Agent multiplexer (tmux for coding agents)"
    echo "  • pi                 - Minimal terminal coding agent (/login then /model)"
    echo "  • codex              - OpenAI Codex CLI (sign in with ChatGPT or OPENAI_API_KEY)"
    echo "  • nvim               - Launch Neovim"
    echo "  • emacs -nw          - Launch Doom Emacs in the terminal"
    echo "  • doom sync          - Reload Doom after editing ~/.config/doom"
    echo "  • <Space>e           - Toggle file explorer (in nvim)"
    echo "  • <Space>ff          - Find files (in nvim)"
    echo "  • <Space>fg          - Live grep (in nvim)"
    echo "  • az login           - Login to Azure"
    echo "  • az --version       - Check Azure CLI version"
    echo "  • fly auth login     - Authenticate with Fly.io (auth signup for a new account)"
    echo "  • fly launch         - Deploy an app to Fly.io from the current directory"
    echo "  • gh auth login      - Authenticate with GitHub"
    echo "  • gh --version       - Check GitHub CLI version"
    echo "  • fnm install <ver>  - Install specific Node.js version"
    echo "  • fnm use <ver>      - Switch Node.js version"
    echo "  • fnm list           - List installed Node.js versions"
    echo "  • uv venv            - Create Python virtual environment"
    echo "  • uv pip install     - Install Python packages (fast!)"
    echo "  • fzf                - Fuzzy finder (Ctrl+R for history search)"
    echo "  • bat <file>         - Cat with syntax highlighting (after stowing zsh)"
    echo "  • rg <pattern>       - Fast recursive search (ripgrep)"
    echo "  • eza -la            - Modern ls replacement"
    echo "  • ncdu               - Disk usage analyzer"
    echo "  • dotnet --info      - Show .NET information"

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
    install_nodejs
    install_rust
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
    install_doom_emacs
    setup_shell

    # Completion
    show_completion_message
}

# Run main only when executed directly, not when sourced. Sourcing then lets you run a
# single installer instead of the whole script — use a subshell so this file's 'set -e'
# doesn't follow you home:
#   bash -c 'source ~/.dotfiles/setup-WSL-ubuntu.sh; install_doom_emacs'
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
