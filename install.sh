#!/bin/bash

# Check if Script is Run as Root
if [[ $EUID -ne 0 ]]; then
  echo "You must be a root user to run this script, please run sudo ./install.sh" 2>&1
  exit 1
fi

username=$(id -u -n 1000)
builddir=$(pwd)

# Update packages list and update system
apt update
apt upgrade -y

# Making .config and Moving config files and background to Pictures
cd $builddir
chown -R $username:$username /home/$username

# Installing Essential Programs 
apt install nala unzip wget build-essential -y

curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/usenala.sh | bash

# Installing Other less important Programs
apt install psmisc vim gdu htop tldr git trash-cli autojump curl fzf bat python3-pip -y

sudo mv /usr/lib/python3.11/EXTERNALLY-MANAGED /usr/lib/python3.11/EXTERNALLY-MANAGED.old

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/devops.sh | bash
curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/docker.sh | bash

curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/nvm.sh | bash

pip install ansible

curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/x11.sh | bash
curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/tools.sh | bash

curl -sSL https://raw.githubusercontent.com/Ujstor/mybash/main/setup.sh | bash
curl -sSL https://raw.githubusercontent.com/Ujstor/tmux-config/master/install.sh | bash
curl -sSL https://raw.githubusercontent.com/Ujstor/nvim-config/master/install.sh | bash

source ~/.bashrc
