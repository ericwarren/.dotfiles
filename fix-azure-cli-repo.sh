#!/bin/bash

# Fix the Azure CLI apt repository on Ubuntu releases Microsoft doesn't publish.
#
# Microsoft's azure-cli feed only ships LTS dists (jammy = 22.04, noble = 24.04).
# On a newer release (e.g. resolute = 26.04) the repo has no Release file, so
# 'apt update' 404s. This script repoints the azure-cli source to the newest
# supported LTS (noble) — its build is pure-Python and runs fine on newer Ubuntu.
#
# Safe to run repeatedly. It touches ONLY the azure-cli source; your main
# ubuntu.sources (which correctly references your real codename) is left alone.
#
# Usage: ./fix-azure-cli-repo.sh

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
print_header()  { echo -e "\n${BLUE}$1${NC}"; echo "=============================================="; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠️${NC} $1"; }
print_error()   { echo -e "${RED}❌${NC} $1"; }

print_header "☁️ Fixing Azure CLI apt repository"

# Microsoft only publishes azure-cli for LTS codenames; anything else falls back
# to the latest supported LTS (noble).
DIST=$(lsb_release -cs 2>/dev/null || echo "")
case "$DIST" in
    jammy|noble)
        print_success "Detected $DIST — natively supported by Microsoft; using as-is"
        AZ_DIST="$DIST"
        ;;
    *)
        AZ_DIST="noble"
        print_warning "Detected '${DIST:-unknown}' (not published by Microsoft) — using noble (24.04)"
        ;;
esac

# Ensure the Microsoft signing key is present (recreate if missing/corrupt).
KEYRING=/etc/apt/keyrings/microsoft.gpg
if [ -s "$KEYRING" ]; then
    print_success "Microsoft signing key already present ($KEYRING)"
else
    echo "Installing Microsoft signing key..."
    sudo mkdir -p /etc/apt/keyrings
    curl -sLS https://packages.microsoft.com/keys/microsoft.asc | \
        gpg --dearmor | \
        sudo tee "$KEYRING" > /dev/null
    sudo chmod go+r "$KEYRING"
    print_success "Microsoft signing key installed"
fi

# Remove any prior azure-cli source in EITHER format so there's exactly one
# definition afterward (the deb822 .sources variant would otherwise still pin the
# stale codename even after we rewrite the .list file).
LIST=/etc/apt/sources.list.d/azure-cli.list
SOURCES=/etc/apt/sources.list.d/azure-cli.sources
for f in "$LIST" "$SOURCES"; do
    if [ -e "$f" ]; then
        echo "Removing existing $f ..."
        sudo rm -f "$f"
    fi
done

echo "Writing $LIST (dist: $AZ_DIST)..."
echo "deb [arch=amd64 signed-by=${KEYRING}] https://packages.microsoft.com/repos/azure-cli/ ${AZ_DIST} main" | \
    sudo tee "$LIST" > /dev/null
print_success "Azure CLI repository repointed to '$AZ_DIST'"

echo "Refreshing package lists..."
sudo apt update

echo "Installing/updating azure-cli..."
sudo apt install -y azure-cli

AZ_VER=$(az version --output tsv --query '"azure-cli"' 2>/dev/null || echo "installed")
print_success "Azure CLI ready: $AZ_VER"
