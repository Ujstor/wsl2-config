#!/bin/bash

# Check if Script is Run as Regular User
if [[ $EUID -eq 0 ]]; then
  echo "This script should be run as a regular user, not root. Run without sudo." 2>&1
  exit 1
fi

username=$(whoami)

# System operations that need sudo
sudo apt update
sudo apt upgrade -y

sudo chown -R $username:$username /home/$username

# Installing Essential Programs 
sudo apt install nala unzip wget build-essential -y

curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/usenala.sh | sudo bash

# Installing Other less important Programs
sudo apt install psmisc vim htop tldr git trash-cli autojump curl fzf bat ripgrep fd-find python3-pip -y

# Handle EXTERNALLY-MANAGED for any Python 3.x version
for python_dir in /usr/lib/python3.*/; do
    if [ -f "${python_dir}EXTERNALLY-MANAGED" ]; then
        sudo mv "${python_dir}EXTERNALLY-MANAGED" "${python_dir}EXTERNALLY-MANAGED.old"
        echo "Moved EXTERNALLY-MANAGED for $(basename $python_dir)"
    fi
done

curl -sSL https://raw.githubusercontent.com/Ujstor/mybash/main/setup.sh | bash
source ~/.bashrc

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/devops.sh | bash
curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/docker.sh | bash

curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/x11.sh | bash

curl -sSL https://raw.githubusercontent.com/Ujstor/tmux-config/master/install.sh | bash
curl -sSL https://raw.githubusercontent.com/Ujstor/nvim-config/master/install.sh | bash


curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/nvm.sh | bash
curl -sSL https://raw.githubusercontent.com/Ujstor/wsl2-config/main/scripts/tools.sh | bash
pip install ansible

echo "Setup completed for user: $username"
