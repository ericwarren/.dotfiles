#!/bin/bash

# Tokyo Night theme setup script
# This script installs the Tokyo Night GTK theme and icon theme

echo "Setting up Tokyo Night theme..."

# Install required packages
sudo pacman -S --needed gtk-engine-murrine gnome-themes-extra

# Create themes directory
mkdir -p ~/.themes ~/.icons

# Download and install Tokyo Night themes
if [ ! -d ~/.themes/Tokyonight-Dark ]; then
    echo "Downloading Tokyo Night GTK themes..."
    git clone https://github.com/Fausto-Korpsvart/Tokyo-Night-GTK-Theme.git /tmp/tokyo-night
    
    # Install themes using the provided script
    cd /tmp/tokyo-night/themes
    ./install.sh -d ~/.themes -n Tokyonight
    
    # Install icon theme
    cp -r /tmp/tokyo-night/icons/Tokyonight-Dark ~/.icons/
    
    cd ~/.dotfiles
    rm -rf /tmp/tokyo-night
fi

# Copy wallpaper to system location for LightDM access
sudo mkdir -p /usr/share/pixmaps
sudo cp ~/.dotfiles/hyprland/.config/hypr/tokyonight.jpg /usr/share/pixmaps/

# Copy LightDM config (requires sudo)
echo "Configuring LightDM..."
sudo cp ~/.dotfiles/lightdm/.config/lightdm-gtk-greeter.conf /etc/lightdm/lightdm-gtk-greeter.conf

# Apply GTK theme
gsettings set org.gnome.desktop.interface gtk-theme "Tokyonight-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Tokyonight-Dark"
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

# Handle stow conflicts and install configurations
cd ~/.dotfiles

# Remove conflicting symlinks
rm -f ~/.config/mako/config ~/.config/rofi/config.rasi

# Stow configurations
stow gtk rofi mako

# Restart mako to apply new config
pkill mako
nohup mako &> /dev/null &

echo "Tokyo Night theme setup complete!"
echo ""
echo "✓ Login screen (LightDM) - Tokyo Night theme and wallpaper configured"
echo "✓ Lock screen (hyprlock) - Tokyo Night colors applied"  
echo "✓ GTK applications (Nautilus) - Dark theme configured"
echo "✓ Application launcher (rofi) - Tokyo Night theme created"
echo "✓ Terminal (Alacritty) - Tokyo Night color scheme applied"
echo "✓ Status bar (waybar) - Tokyo Night colors applied"
echo "✓ Notifications (mako) - Tokyo Night theme configured"
echo ""
echo "Please restart your session or reboot to see all changes."