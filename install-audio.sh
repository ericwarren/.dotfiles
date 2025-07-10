#!/bin/bash
# Install Pipewire audio stack for Arch Linux

echo "Installing Pipewire audio stack..."

# Install pipewire and related packages
sudo pacman -S --needed pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber pavucontrol

# Enable pipewire services for user
systemctl --user enable --now pipewire.service
systemctl --user enable --now pipewire-pulse.service
systemctl --user enable --now wireplumber.service

echo "Audio stack installed. You may need to log out and back in for full functionality."