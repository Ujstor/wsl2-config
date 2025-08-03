#!/bin/bash

if [[ -f "$HOME/.bashrc" ]]; then
    set +e  # Temporarily disable exit on error
    source "$HOME/.bashrc" 2>/dev/null || true
    set -e  # Re-enable exit on error
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing NVM and Node.js 22...${NC}"

# Check if NVM is already installed
if command -v nvm &> /dev/null; then
    echo -e "${YELLOW}NVM is already installed. Skipping installation.${NC}"
else
    echo -e "${GREEN}Downloading and installing NVM (latest version v0.40.3)...${NC}"

    # Install NVM using curl (fallback to wget if curl is not available)
    if command -v curl &> /dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    elif command -v wget &> /dev/null; then
        wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    else
        echo -e "${RED}Error: Neither curl nor wget is available. Please install one of them first.${NC}"
        exit 1
    fi

    echo -e "${GREEN}NVM installation completed.${NC}"
fi

# Load NVM into current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Function to check if NVM is loaded
check_nvm() {
    if command -v nvm &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Try to load NVM and check if it's working
if ! check_nvm; then
    echo -e "${YELLOW}Loading NVM for current session...${NC}"

    # Try different shell profiles
    for profile in ~/.bashrc ~/.bash_profile ~/.zshrc ~/.profile; do
        if [ -f "$profile" ]; then
            source "$profile" 2>/dev/null && break
        fi
    done
fi

# Final check for NVM
if check_nvm; then
    echo -e "${GREEN}NVM version: $(nvm --version)${NC}"

    # Install Node.js 22 (latest LTS)
    echo -e "${GREEN}Installing Node.js 22...${NC}"
    nvm install 22

    # Set Node.js 22 as default
    echo -e "${GREEN}Setting Node.js 22 as default...${NC}"
    nvm alias default 22

    # Use Node.js 22
    nvm use 22

    # Verify installation
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${GREEN}Node.js version: $(node --version)${NC}"
    echo -e "${GREEN}NPM version: $(npm --version)${NC}"

else
    echo -e "${RED}Error: NVM installation failed or not available in current session.${NC}"
    echo -e "${YELLOW}Please restart your terminal or manually run:${NC}"
    echo -e "${YELLOW}source ~/.bashrc    # for bash${NC}"
    echo -e "${YELLOW}source ~/.zshrc     # for zsh${NC}"
    echo -e "${YELLOW}Then run: nvm install 22 && nvm use 22${NC}"
    exit 1
fi

echo -e "${YELLOW}Note: If this is your first NVM installation, you may need to:${NC}"
echo -e "${YELLOW}1. Restart your terminal, OR${NC}"
echo -e "${YELLOW}2. Run: source ~/.bashrc (or ~/.zshrc if using zsh)${NC}"
echo -e "${YELLOW}3. Verify with: nvm --version${NC}"
