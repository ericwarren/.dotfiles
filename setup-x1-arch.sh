#!/bin/bash
set -euo pipefail

# Minimal Arch Package Installation - Only Hyprland + Wezterm

echo "=== Minimal Arch Installation ==="
echo "Installing only Hyprland and wezterm with essential dependencies"
echo
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Update system
echo "Updating system..."
sudo pacman -Syu --noconfirm

# Install Hyprland
echo "Installing Hyprland..."
sudo pacman -S --noconfirm hyprland

# Install wezterm
echo "Installing wezterm..."
sudo pacman -S --noconfirm wezterm

# Install GNU Stow for dotfile management
echo "Installing GNU Stow..."
sudo pacman -S --noconfirm stow

echo
echo "=== Installation complete! ==="
echo
echo "Hyprland and wezterm are now installed."
echo "To start Hyprland, type 'Hyprland' in the TTY"
echo
echo "Next: Set up config files using stow"