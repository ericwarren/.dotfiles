

# Use the recommended Nix option based on operating system
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    echo "This is WSL"
    sh <(curl -L https://nixos.org/nix/install) --no-daemon
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "This is a Mac"
    sh <(curl -L https://nixos.org/nix/install)
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "This is Linux"
    sh <(curl -L https://nixos.org/nix/install) --daemon
fi

# source nix
. ~/.nix-profile/etc/profile.d/nix.sh

# install packages
nix-env -iA \
	nixpkgs.zsh \
	nixpkgs.antibody \
	nixpkgs.git \
	nixpkgs.neovim \
	nixpkgs.stow \
	nixpkgs.bat \
    nixpkgs.fzf 	
    nixpkgs.gnumake \
	nixpkgs.gcc \	
    nixpkgs.erlang \
	nixpkgs.elixir \
	nixpkgs.python310 \
	nixpkgs.jq \
	nixpkgs.keychain

# stow dotfiles
stow git
stow nvim
stow zsh

# add zsh as a login shell
command -v zsh | sudo tee -a /etc/shells

# use zsh as default shell
sudo chsh -s $(which zsh) $USER

# bundle zsh plugins 
antibody bundle < ~/.zsh_plugins.txt > ~/.zsh_plugins.sh

# install neovim plugins
nvim --headless +PlugInstall +qall