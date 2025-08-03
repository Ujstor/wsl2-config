#!/bin/bash

# Enhanced System Setup Script
# Installs Brave Browser, GitHub CLI, and Go tools with proper error handling

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Error handler
error_exit() {
    log_error "$1"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error_exit "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Check sudo privileges
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_info "This script requires sudo privileges. You may be prompted for your password."
        sudo -v || error_exit "Failed to obtain sudo privileges"
    fi
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    if ! sudo nala update && sudo nala upgrade -y; then
        error_exit "Failed to update system packages"
    fi
    log_success "System packages updated"
}

# Install base dependencies
install_base_deps() {
    log_info "Installing base dependencies..."
    local deps="software-properties-common apt-transport-https curl ca-certificates"

    if ! sudo nala install $deps -y; then
        error_exit "Failed to install base dependencies"
    fi
    log_success "Base dependencies installed"
}

# Install Brave Browser
install_brave() {
    log_info "Installing Brave Browser..."

    # Download and add GPG key
    if ! wget -qO- https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg | \
         sudo gpg --dearmor | \
         sudo tee /usr/share/keyrings/brave-browser-archive-keyring.gpg > /dev/null; then
        error_exit "Failed to add Brave GPG key"
    fi

    # Add repository
    local repo_line="deb [arch=amd64 signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"
    if ! echo "$repo_line" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null; then
        error_exit "Failed to add Brave repository"
    fi

    # Update and install
    if ! sudo nala update || ! sudo nala install brave-browser -y; then
        error_exit "Failed to install Brave Browser"
    fi

    log_success "Brave Browser installed"
}

# Install GitHub CLI
install_github_cli() {
    log_info "Installing GitHub CLI..."

    # Ensure curl is available
    if ! command -v curl &> /dev/null; then
        log_info "Installing curl..."
        if ! sudo nala update && sudo nala install curl -y; then
            error_exit "Failed to install curl"
        fi
    fi

    # Add GitHub CLI repository and install
    if ! curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
         sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
         sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg; then
        error_exit "Failed to add GitHub CLI GPG key"
    fi

    local repo_line="deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"
    if ! echo "$repo_line" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null; then
        error_exit "Failed to add GitHub CLI repository"
    fi

    if ! sudo nala update || ! sudo nala install gh -y; then
        error_exit "Failed to install GitHub CLI"
    fi

    log_success "GitHub CLI installed"
}

# Check and validate Go installation
check_go() {
    log_info "Checking Go installation..."

    # Check if go is available in PATH for current user
    if command -v go &> /dev/null; then
        local go_version
        go_version=$(go version 2>/dev/null || echo "unknown")
        log_success "Go is installed: $go_version"
        return 0
    else
        log_error "Go is not installed or not in PATH for user $USER."
        log_info "Please install Go from: https://golang.org/doc/install"
        log_info "Or use your package manager: sudo nala install golang-go"
        log_info "Make sure to add Go to your PATH in ~/.bashrc or ~/.profile"
        return 1
    fi
}

# Install Go tools
install_go_tools() {
    log_info "Installing Go tools..."

    local tools=(
        "github.com/hetznercloud/cli/cmd/hcloud@latest"
        "github.com/dundee/gdu@latest"
        "github.com/melkeydev/go-blueprint@latest"
    )

    for tool in "${tools[@]}"; do
        local tool_name
        tool_name=$(basename "$(echo "$tool" | cut -d'@' -f1)")

        log_info "Installing $tool_name..."
        if ! go install "$tool"; then
            log_error "Failed to install $tool_name"
            continue
        fi
        log_success "$tool_name installed"
    done
}

# Display summary
show_summary() {
    log_info "Installation Summary:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check installed software
    command -v brave-browser &> /dev/null && echo -e "${GREEN}✓${NC} Brave Browser" || echo -e "${RED}✗${NC} Brave Browser"
    command -v gh &> /dev/null && echo -e "${GREEN}✓${NC} GitHub CLI" || echo -e "${RED}✗${NC} GitHub CLI"
    command -v go &> /dev/null && echo -e "${GREEN}✓${NC} Go" || echo -e "${RED}✗${NC} Go"

    # Check Go tools (only if Go is available)
    if command -v go &> /dev/null; then
        local go_bin_path="$(go env GOPATH 2>/dev/null)/bin"
        [[ -f "$go_bin_path/hcloud" ]] && echo -e "${GREEN}✓${NC} Hetzner Cloud CLI" || echo -e "${RED}✗${NC} Hetzner Cloud CLI"
        [[ -f "$go_bin_path/go-blueprint" ]] && echo -e "${GREEN}✓${NC} Go Blueprint" || echo -e "${RED}✗${NC} Go Blueprint"
    else
        echo -e "${RED}✗${NC} Hetzner Cloud CLI (Go not available)"
        echo -e "${RED}✗${NC} Go Blueprint (Go not available)"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main execution
main() {
    log_info "Starting system setup..."

    check_root
    check_sudo

    update_system
    install_base_deps
    install_brave
    install_github_cli

    if check_go; then
        install_go_tools
    else
        log_warning "Skipping Go tools installation due to missing Go"
    fi

    show_summary
    log_success "Setup completed!"
}

# Run main function
main "$@"
