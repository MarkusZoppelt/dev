#!/bin/bash

# if running as root, create user mz and exit
if [ "$EUID" -eq 0 ]; then
    echo "Running as root, creating user mz"
    useradd -m mz
    usermod -aG sudo mz
    echo "Please set a password for mz"
    passwd mz
    echo "User mz created. Please log in as mz and re-run the script:"
    echo "    curl -fsSL https://zoppelt.net/dev/install.sh | bash -i"
    exit
fi

echo "Updating and upgrading system"
sudo apt update -y
sudo apt upgrade -y
sudo apt install curl git zsh -y

echo "Setting zsh as default shell"
sudo chsh -s /bin/zsh mz

echo "Cloning dotfiles"
git clone https://github.com/MarkusZoppelt/dotfiles.git ~/.dotfiles

echo "Installing dotfiles"
cd ~/.dotfiles
bash install.sh
cd -

echo "Installing Nix via determinate systems installer"
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

echo "Sourcing Nix"
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

mkdir -p ~/code
echo "Cloning nix configuration"
git clone https://github.com/MarkusZoppelt/nix.git ~/code/nix

echo "Installing from flake"
cd ~/code/nix
nix run nixpkgs#home-manager -- switch --flake .#Linux
cd -

echo "Installing tailscale"
curl -fsSL https://tailscale.com/install.sh | sh

echo "Starting Zsh"
zsh
