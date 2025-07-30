#!/bin/bash

# Check if ~/.zshrc exists and back it up
if [ -f "$HOME/.zshrc" ]; then
    echo "Found existing ~/.zshrc, backing up to ~/.zshrc.backup"
    mv "$HOME/.zshrc" "$HOME/.zshrc.backup"
else
    echo "No existing ~/.zshrc found"
fi

# Run stow for zsh and git
echo "Stowing zsh configuration..."
stow zsh -d  /workspaces/.codespaces/.persistedshare/dotfiles -t ~ -v

echo "Stowing git configuration..."
stow git -d  /workspaces/.codespaces/.persistedshare/dotfiles -t ~ -v

# Set git email address
git config user.email "eric.warren7@gmail.com"

# Set node version
nvm use --lts

# Install Claude Code
echo "Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

echo "Setup complete!"