

# Use the recommended Nix option based on operating system
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    echo "This is WSL"
    sh <(curl -L https://nixos.org/nix/install) --no-daemon
fi

# source nix
. ~/.nix-profile/etc/profile.d/nix.sh

# install packages
nix-env -iA \
	nixpkgs.zsh \
	nixpkgs.git \
	nixpkgs.stow \
	nixpkgs.bat \
	nixpkgs.fzf \
	nixpkgs.ripgrep \
	nixpkgs.jq \
	nixpkgs.keychain

# stow dotfiles
stow git
stow zsh


# Download zsh completion files
curl -o ~/.zsh/git-completion.bash --create-dirs https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o ~/.zsh/_git --create-dirs https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh

# Install Antidote zsh plugin manager
git clone --depth=1 https://github.com/mattmc3/antidote.git ${ZDOTDIR:-~}/.antidote

#install for language server support
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
nvm install 16
nvm use 16
npm install -g typescript typescript-language-server

# add zsh as a login shell
command -v zsh | sudo tee -a /etc/shells

# use zsh as default shell
sudo chsh -s $(which zsh) $USER

# bundle zsh plugins 
antidote bundle < ~/.zsh_plugins.txt > ~/.zsh_plugins.sh

# install neovim plugins
# nvim --headless +PlugInstall +qall
