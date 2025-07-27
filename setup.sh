#!/bin/bash

# Setup file for Github Codespaces

# Check if ~/.zshrc exists and back it up
if [ -f "$HOME/.zshrc" ]; then
    echo "Found existing ~/.zshrc, backing up to ~/.zshrc.backup"
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
else
    echo "No existing ~/.zshrc found"
fi

# Run stow for zsh and git
echo "Stowing zsh configuration..."
stow zsh

echo "Stowing git configuration..."
stow git

# Install Claude Code
echo "Installing Claude Code..."
npm install -g @anthropic/claude-code

echo "Setup complete!"
