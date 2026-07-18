#!/bin/bash

# vulcan (Ubuntu Server 26.04) provisioning script
# Remote dev backend: Rider/.NET, Rust, Docker. GPU/LLM phase deliberately deferred.
#
# Run ON vulcan, as the normal user (eric), one phase at a time:
#   ./setup-vulcan-server.sh phase0            # base config + sshd hardening (NO firewall yet)
#   ./setup-vulcan-server.sh phase0-firewall   # enable UFW — run only after key auth is verified from the laptop
#   ./setup-vulcan-server.sh phase1            # .NET SDK + gh + git config (Rider backend needs nothing else)
#   ./setup-vulcan-server.sh phase2            # Rust toolchain via rustup
#   ./setup-vulcan-server.sh phase3            # Docker Engine from Docker's apt repo
#
# Every step is idempotent — re-running a phase is safe.
#
# RECOVERY PATHS (memorize before phase0-firewall):
#   - Tailscale SSH is handled inside tailscaled, independent of sshd config and
#     allowed through the firewall rules below. It keeps working even if sshd is
#     misconfigured.
#   - From the GL.iNet Comet KVM console:  sudo ufw disable        # undo firewall
#                                          sudo rm /etc/ssh/sshd_config.d/10-hardening.conf
#                                          sudo systemctl restart ssh   # undo sshd hardening

set -e

export DEBIAN_FRONTEND=noninteractive

# Laptop public key (X1 Carbon, ~/.ssh/id_ed25519.pub) — embedded so the script
# is self-contained on the server.
LAPTOP_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJj1qirWLuiT0Bngd6Re7znU2NF7ANkP0G4VInoGa01k eric.warren7@gmail.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

check_host() {
    if [ "$(hostname)" != "vulcan" ]; then
        print_error "This script is for vulcan only (detected: $(hostname))"
        exit 1
    fi
}

# ============================================================
# Phase 0 — base configuration + sshd hardening
# ============================================================

set_timezone() {
    print_header "🕐 Timezone"
    if [ "$(timedatectl show -p Timezone --value)" = "America/Chicago" ]; then
        print_success "Timezone already America/Chicago"
    else
        sudo timedatectl set-timezone America/Chicago
        print_success "Timezone set to America/Chicago"
    fi
}

verify_unattended_upgrades() {
    print_header "🔄 Unattended security upgrades"

    # /etc/apt/apt.conf.d/20auto-upgrades is what actually turns the machinery
    # on: "Update-Package-Lists" refreshes the index, "Unattended-Upgrade" lets
    # the daily systemd timer install security updates. Both must be "1".
    local conf=/etc/apt/apt.conf.d/20auto-upgrades
    if [ ! -f "$conf" ] || ! grep -q 'Unattended-Upgrade "1"' "$conf"; then
        echo 'APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";' | sudo tee "$conf" > /dev/null
        print_success "Enabled periodic unattended upgrades in $conf"
    else
        print_success "$conf already enables unattended upgrades"
    fi

    # The timer that fires the actual upgrade run.
    if systemctl is-active --quiet apt-daily-upgrade.timer; then
        print_success "apt-daily-upgrade.timer is active"
    else
        sudo systemctl enable --now apt-daily-upgrade.timer
        print_success "apt-daily-upgrade.timer enabled"
    fi

    # Dry run proves the config parses and the security origin is matched —
    # "verified, not merely installed".
    echo "Running unattended-upgrade --dry-run (takes a few seconds)..."
    if sudo unattended-upgrade --dry-run > /dev/null 2>&1; then
        print_success "unattended-upgrade dry run OK"
    else
        print_error "unattended-upgrade dry run failed — investigate before relying on it"
        exit 1
    fi
}

install_ssh_key() {
    print_header "🔑 Laptop SSH key"
    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
    if grep -qF "$LAPTOP_PUBKEY" ~/.ssh/authorized_keys; then
        print_success "Laptop key already in authorized_keys"
    else
        echo "$LAPTOP_PUBKEY" >> ~/.ssh/authorized_keys
        print_success "Laptop key added to authorized_keys"
    fi
}

harden_sshd() {
    print_header "🔒 sshd hardening"

    # Ubuntu starts sshd through systemd *socket activation* (ssh.socket):
    # systemd owns the listening socket and hands connections to sshd, so any
    # "ListenAddress" line in sshd_config is silently ignored. The old
    # 99-local.conf tried to bind sshd to the tailnet IP that way — it never
    # took effect (sshd was listening on 0.0.0.0). It is also a latent trap: if
    # socket activation were ever disabled, sshd would try to bind the tailnet
    # IP at boot before tailscaled is up, and fail. Exposure is handled by UFW
    # instead (phase0-firewall), so remove it.
    if [ -f /etc/ssh/sshd_config.d/99-local.conf ]; then
        sudo rm /etc/ssh/sshd_config.d/99-local.conf
        print_success "Removed ineffective 99-local.conf (ListenAddress is ignored under socket activation)"
    else
        print_success "99-local.conf already removed"
    fi

    # Key-only auth. Password auth over the network is the thing worth turning
    # off while sshd is reachable beyond the tailnet; the KVM console login is
    # unaffected (that's a local tty, not sshd).
    local conf=/etc/ssh/sshd_config.d/10-hardening.conf
    if [ -f "$conf" ] && grep -q "^PasswordAuthentication no" "$conf"; then
        print_success "Password authentication already disabled"
    else
        echo 'PasswordAuthentication no' | sudo tee "$conf" > /dev/null
        # -t = test mode: parse the config and exit non-zero on errors, so a
        # typo can't take sshd down on restart.
        sudo sshd -t
        sudo systemctl restart ssh
        print_success "Password authentication disabled (key + Tailscale SSH only)"
    fi
}

phase0() {
    check_host
    set_timezone
    verify_unattended_upgrades
    install_ssh_key
    harden_sshd

    print_header "✅ Phase 0 (pre-firewall) complete"
    print_warning "BEFORE running phase0-firewall, verify key-based ssh from the laptop"
    print_warning "against the LAN address (the tailnet path goes through Tailscale SSH"
    print_warning "and would not exercise sshd key auth):"
    echo
    echo "    ssh -o PreferredAuthentications=publickey eric@10.0.0.216 true && echo KEY-AUTH-OK"
    echo
    print_warning "Then run:  ./setup-vulcan-server.sh phase0-firewall"
}

# ============================================================
# Phase 0b — firewall (run only after key auth verified)
# ============================================================

phase0_firewall() {
    check_host
    print_header "🧱 UFW firewall — tailnet-only"

    # Default posture: drop everything inbound, allow everything outbound.
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Allow anything arriving on the Tailscale interface. Tailscale traffic is
    # already authenticated/encrypted by WireGuard before it reaches this
    # interface, so interface-scoped allow is the whole tailnet story.
    sudo ufw allow in on tailscale0 comment 'tailnet'

    # Tailscale's WireGuard port. Without this, inbound direct connections are
    # dropped and peers fall back to relaying through DERP servers — noticeably
    # worse latency for Rider remote dev.
    sudo ufw allow in 41641/udp comment 'tailscale direct connections'

    # --force skips the interactive "may disrupt ssh" prompt. Recovery from the
    # KVM console: sudo ufw disable
    sudo ufw --force enable

    sudo ufw status verbose
    print_success "UFW enabled: inbound only via tailscale0 + WireGuard UDP"
    print_warning "Verify from the laptop:"
    echo "    nc -zw2 100.111.73.55 22   # should succeed (tailnet)"
    echo "    nc -zw2 10.0.0.216 22      # should now FAIL (LAN blocked)"
}

# ============================================================
# Phase 1 — .NET + Rider backend prerequisites
# ============================================================

install_dotnet() {
    print_header "📦 .NET SDK 10 (Ubuntu archive)"

    # Ubuntu's own archive: Canonical builds dotnet-sdk-10.0 for 26.04 and
    # security updates flow through unattended-upgrades like any other package.
    # Microsoft's packages.microsoft.com feed no longer ships .NET for current
    # Ubuntu releases (they defer to the distro packages), so the historical
    # "same package name, two feeds" conflict doesn't apply — no pinning needed.
    if dotnet --list-sdks 2>/dev/null | grep -q '^10\.'; then
        print_success ".NET SDK 10 already installed: $(dotnet --version)"
        return
    fi

    sudo apt update
    sudo apt install -y dotnet-sdk-10.0
    print_success ".NET SDK installed: $(dotnet --version)"
}

install_github_cli() {
    print_header "🐙 GitHub CLI"

    if command -v gh &> /dev/null; then
        print_success "GitHub CLI already installed: $(gh --version | head -n1)"
        return
    fi

    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    sudo apt update
    sudo apt install -y gh
    print_success "GitHub CLI installed: $(gh --version | head -n1)"
}

configure_git() {
    print_header "🔧 Git configuration"

    # Minimal per-server config rather than stowing the dotfiles .gitconfig,
    # which hardcodes laptop-specific credential helper paths.
    git config --global user.name "Eric Warren"
    git config --global user.email "eric.warren7@gmail.com"
    git config --global init.defaultBranch main
    git config --global pull.rebase true
    git config --global alias.s status
    git config --global alias.lol "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    git config --global alias.co checkout
    git config --global alias.up '!git pull --rebase --prune $@ && git submodule update --init --recursive'
    # gh doubles as the credential helper for HTTPS clones of private repos.
    git config --global credential.https://github.com.helper '!/usr/bin/gh auth git-credential'

    mkdir -p ~/src
    print_success "Git configured; ~/src created for projects"
}

phase1() {
    check_host
    install_dotnet
    install_github_cli
    configure_git

    print_header "✅ Phase 1 complete"
    print_warning "One-time interactive step:  gh auth login"
    print_warning "Acceptance test (from the laptop): JetBrains Gateway → SSH eric@vulcan →"
    print_warning "open a solution, build, run tests, hit a breakpoint."
    echo "  (Gateway uploads the Rider backend itself on first connect — nothing to preinstall.)"
}

# ============================================================
# Phase 2 — Rust
# ============================================================

install_build_essentials() {
    print_header "🔨 Build essentials"
    # cc/ld for cargo's linking step, pkg-config + libssl-dev for the most
    # common native-dependency crates (openssl-sys and friends).
    sudo apt update
    sudo apt install -y build-essential pkg-config libssl-dev
    print_success "build-essential, pkg-config, libssl-dev installed"
}

install_rust() {
    print_header "🦀 Rust toolchain (rustup)"

    # rustup, not apt: Ubuntu's packaged Rust lags releases and can't manage
    # components (rust-analyzer, clippy) per-toolchain. rustup installs
    # everything under ~/.cargo and ~/.rustup for this user only — no sudo.
    if [ -f "$HOME/.cargo/bin/rustup" ]; then
        print_success "rustup already installed"
    else
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
            sh -s -- -y --default-toolchain stable
        print_success "rustup + stable toolchain installed"
    fi

    # shellcheck disable=SC1091
    source "$HOME/.cargo/env"
    rustup component add rust-analyzer clippy rustfmt
    print_success "rust-analyzer, clippy, rustfmt available"
    rustc --version
}

phase2() {
    check_host
    install_build_essentials
    install_rust

    print_header "✅ Phase 2 complete"
    print_warning "Acceptance: cargo new/build/test here, then open a file from the laptop's"
    print_warning "Emacs via /ssh:vulcan:~/src/... and confirm eglot completion + diagnostics."
}

# ============================================================
# Phase 3 — Docker
# ============================================================

install_docker() {
    print_header "🐳 Docker Engine (Docker's apt repository)"

    if command -v docker &> /dev/null; then
        print_success "Docker already installed: $(docker --version)"
    else
        # Docker's own repo, not docker.io: upstream packages track releases and
        # match Docker's documentation. Their repo publishes a dist for 26.04
        # ("resolute") — verified before this script was written.
        sudo mkdir -p -m 755 /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        print_success "Docker installed: $(docker --version)"
    fi

    # Cap container logs. The default json-file driver has NO size limit — a
    # chatty container (SQL Server is one) would slowly eat the 100G root LV.
    # 10m x 3 files = max 30MB of logs per container.
    if [ -f /etc/docker/daemon.json ]; then
        print_warning "/etc/docker/daemon.json already exists — not overwriting. Current contents:"
        sudo cat /etc/docker/daemon.json
    else
        echo '{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}' | sudo tee /etc/docker/daemon.json > /dev/null
        sudo systemctl restart docker
        print_success "Log rotation configured (10m x 3 per container)"
    fi

    # NOTE: membership in the docker group is effectively passwordless root on
    # this host (the daemon runs as root and will happily mount / for you).
    # Accepted trade-off on a single-user dev box — but that is what this is.
    if id -nG "$USER" | grep -qw docker; then
        print_success "$USER already in docker group"
    else
        sudo usermod -aG docker "$USER"
        print_warning "$USER added to docker group — takes effect on next login (or: newgrp docker)"
    fi

    # GPU phase hook (deliberately NOT done now): when the LLM phase happens,
    # install the NVIDIA Container Toolkit to hand the 3090 to containers.

    echo "Running hello-world..."
    sudo docker run --rm hello-world > /dev/null && print_success "hello-world ran OK"
}

phase3() {
    check_host
    install_docker

    print_header "✅ Phase 3 complete"
    print_warning "Acceptance: Testcontainers smoke test (~/src/tc-smoke) — dotnet test"
    print_warning "against a containerized SQL Server."
    echo "Root LV usage after Docker install:"
    df -h /
}

# ============================================================
# Dispatch
# ============================================================

case "${1:-}" in
    phase0)          phase0 ;;
    phase0-firewall) phase0_firewall ;;
    phase1)          phase1 ;;
    phase2)          phase2 ;;
    phase3)          phase3 ;;
    *)
        echo "Usage: $0 {phase0|phase0-firewall|phase1|phase2|phase3}"
        echo
        echo "  phase0           Timezone, unattended upgrades, ssh key, sshd hardening"
        echo "  phase0-firewall  Enable UFW (only after key auth verified from laptop)"
        echo "  phase1           .NET SDK 10, GitHub CLI, git config"
        echo "  phase2           Rust via rustup (+ build essentials)"
        echo "  phase3           Docker Engine + log rotation + docker group"
        exit 1
        ;;
esac
