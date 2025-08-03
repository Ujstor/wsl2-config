#!/bin/bash

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
    echo -e "${GREEN}Downloading and installing NVM...${NC}"

    # Install NVM using curl (fallback to wget if curl is not available)
    if command -v curl &> /dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    elif command -v wget &> /dev/null; then
        wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    else
        echo -e "${RED}Error: Neither curl nor wget is available. Please install one of them first.${NC}"
        exit 1
    fi

    # Add NVM to current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    echo -e "${GREEN}NVM installation completed.${NC}"
fi

# Source NVM to make sure it's available in current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Verify NVM installation
if ! command -v nvm &> /dev/null; then
    echo -e "${RED}Error: NVM installation failed or not available in current session.${NC}"
    echo -e "${YELLOW}Please restart your terminal or run: source ~/.bashrc${NC}"
    exit 1
fi

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
echo -e "${GREEN}Installation completed!${NC}"
echo -e "${GREEN}Node.js version: $(node --version)${NC}"
echo -e "${GREEN}NPM version: $(npm --version)${NC}"

echo -e "${YELLOW}Note: If this is your first time installing NVM, you may need to restart your terminal or run:${NC}"
echo -e "${YELLOW}source ~/.bashrc${NC}"
echo -e "${YELLOW}(or source ~/.zshrc if you're using zsh)${NC}"
