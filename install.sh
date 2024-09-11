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

echo "🚀 Updating and upgrading system"
sudo apt update -y
sudo apt upgrade -y
sudo apt install clang cmake curl git lcov llvm zsh -y

echo "🚀 Installing Nix via determinate systems installer"
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm

echo "🚀 Sourcing Nix"
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

mkdir -p ~/code
echo "🚀 Cloning nix configuration"
git clone https://github.com/MarkusZoppelt/nix.git ~/code/nix

echo "🚀 Installing from flake"
cd ~/code/nix
nix run nixpkgs#home-manager -- switch --flake .#Linux
cd -

# now we have gum and can use it

gum style --foreground 110 --bold "🚀 Setting zsh as default shell"
sudo chsh -s /bin/zsh mz

gum style --foreground 110 --bold "🚀 Cloning dotfiles"
git clone https://github.com/MarkusZoppelt/dotfiles.git ~/.dotfiles

gum style --foreground 110 --bold "🚀 Installing dotfiles"
cd ~/.dotfiles
bash install.sh
cd -

if gum confirm "Do you want to setup docker?"; then
    gum style --foreground 110 --bold "🚀 Installing Docker"
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
    sudo apt-get install ca-certificates curl uuidmap -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Setting up Docker rootless"
    gum style --foreground 110 --bold "If you want to setup Docker rootless, please run the following commands:"
    gum style --foreground 110 --bold "    sudo systemctl disable --now docker.service docker.socket"
    gum style --foreground 110 --bold "    sudo rm /var/run/docker.sock"
    gum style --foreground 110 --bold "    dockerd-rootless-setuptool.sh install"
fi

if gum confirm "Do you want to setup Tailscale?"; then
    gum style --foreground 110 --bold "🚀 Installing Tailscale"
    curl -fsSL https://tailscale.com/install.sh | sh
fi

if gum confirm "Is this a Desktop? (i.e. should we setup GUI options and applications?)"; then
    gum style --foreground 110 --bold "🚀 Setting up GUI options"
    if lspci | rg NVIDIA; then
        gum style --foreground 110 --bold "🚀 Setting up NVIDIA shenanigans"
        sudo apt install nvidia-vaapi-driver libnvidia-egl-wayland1 -y
    fi
    sudo apt install alacritty -y
    gsettings set org.gnome.desktop.interface enable-animations false

    # Use 6 fixed workspaces instead of dynamic mode
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 5

    # Use alt for pinned apps
    gsettings set org.gnome.shell.keybindings switch-to-application-1 "['<Alt>1']"
    gsettings set org.gnome.shell.keybindings switch-to-application-2 "['<Alt>2']"
    gsettings set org.gnome.shell.keybindings switch-to-application-3 "['<Alt>3']"
    gsettings set org.gnome.shell.keybindings switch-to-application-4 "['<Alt>4']"
    gsettings set org.gnome.shell.keybindings switch-to-application-5 "['<Alt>5']"
    gsettings set org.gnome.shell.keybindings switch-to-application-6 "['<Alt>6']"
    gsettings set org.gnome.shell.keybindings switch-to-application-7 "['<Alt>7']"
    gsettings set org.gnome.shell.keybindings switch-to-application-8 "['<Alt>8']"
    gsettings set org.gnome.shell.keybindings switch-to-application-9 "['<Alt>9']"

    # Use super for workspaces
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<Super>5']"
fi

gum style --foreground 110 --bold "Starting zsh"
zsh
