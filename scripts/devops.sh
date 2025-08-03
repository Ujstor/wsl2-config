#!/bin/bash

# DevOps Tools Installation Script
# Installs Go, Docker, Kubernetes tools, Terraform, and other development tools

set -e

# Configuration
readonly DOWNLOAD_DIR="$HOME/Downloads"
readonly GO_VERSION="go1.24.0"
readonly GO_URL="https://golang.org/dl/${GO_VERSION}.linux-amd64.tar.gz"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create download directory if it doesn't exist
mkdir -p "$DOWNLOAD_DIR"

# Function to completely clean Go installation
clean_go_installation() {
    log_warn "Performing complete Go cleanup..."

    # Remove all possible Go installations
    sudo rm -rf /usr/local/go
    sudo rm -rf /usr/lib/go*
    sudo rm -rf /usr/share/go*

    # Remove from package manager if installed via apt
    if dpkg -l | grep -q golang 2>/dev/null; then
        log_info "Removing Go packages from apt..."
        sudo nala remove -y golang-* 2>/dev/null || true
        sudo nala autoremove -y 2>/dev/null || true
    fi

    # Clean up Go-related environment variables from bashrc
    sed -i '/export PATH.*\/usr\/local\/go\/bin/d' ~/.bashrc
    sed -i '/export GOROOT/d' ~/.bashrc
    sed -i '/export GOPATH/d' ~/.bashrc
    sed -i '/export GOCACHE/d' ~/.bashrc
    sed -i '/# Go environment variables/d' ~/.bashrc

    # Clear Go cache and modules
    rm -rf "$HOME/.cache/go-build" 2>/dev/null || true
    rm -rf "$HOME/go/pkg" 2>/dev/null || true

    # Unset Go environment variables for current session
    unset GOROOT GOPATH GOCACHE PATH_BACKUP 2>/dev/null || true

    log_info "Go cleanup completed"
}

# Function to install Go
install_go() {
    log_info "Checking Go installation..."

    local needs_install=false
    local current_version=""

    # Check if Go is installed and get current version
    if command -v go &> /dev/null; then
        current_version=$(go version 2>/dev/null | awk '{print $3}' || echo "unknown")
        log_info "Current Go version: $current_version"

        # Check if version matches and Go is working properly
        if [ "$current_version" != "$GO_VERSION" ] || [ "$current_version" = "unknown" ]; then
            log_warn "Go version mismatch or corrupted installation detected"
            needs_install=true
        else
            # Test if Go compilation works
            log_info "Testing Go compilation..."
            local temp_dir=$(mktemp -d)
            echo 'package main
import "fmt"
func main() { fmt.Println("test") }' > "$temp_dir/test.go"

            if go run "$temp_dir/test.go" &>/dev/null; then
                log_info "Go $GO_VERSION is already installed and working properly"
                rm -rf "$temp_dir"
                return 0
            else
                log_warn "Go compilation test failed, reinstalling..."
                needs_install=true
            fi
            rm -rf "$temp_dir"
        fi
    else
        log_info "Go not found, installing..."
        needs_install=true
    fi

    if [ "$needs_install" = true ]; then
        # Clean any existing installation
        clean_go_installation

        log_info "Installing Go $GO_VERSION..."

        # Download Go if not already present
        if [ ! -f "${DOWNLOAD_DIR}/${GO_VERSION}.linux-amd64.tar.gz" ]; then
            log_info "Downloading Go $GO_VERSION..."
            wget -P "$DOWNLOAD_DIR" "$GO_URL"
        fi

        # Extract and install
        log_info "Extracting and installing Go..."
        sudo tar -C /usr/local -xzf "${DOWNLOAD_DIR}/${GO_VERSION}.linux-amd64.tar.gz"

        # Create Go workspace
        mkdir -p "$HOME/go"

        # Add Go environment variables to bashrc
        log_info "Setting up Go environment variables..."
        {
            echo ''
            echo '# Go environment variables'
            echo 'export GOROOT=/usr/local/go'
            echo 'export GOPATH=$HOME/go'
            echo 'export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin'
            echo 'export GOCACHE=$HOME/.cache/go-build'
        } >> ~/.bashrc

        # Export for current session
        export GOROOT=/usr/local/go
        export GOPATH=$HOME/go
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
        export GOCACHE=$HOME/.cache/go-build

        # Create necessary directories
        mkdir -p "$GOPATH/src" "$GOPATH/bin" "$GOPATH/pkg"
        mkdir -p "$GOCACHE"

        # Clean up downloaded file
        rm -f "${DOWNLOAD_DIR}/${GO_VERSION}.linux-amd64.tar.gz"

        # Verify installation
        if /usr/local/go/bin/go version &>/dev/null; then
            log_info "Go $GO_VERSION installed successfully"
            log_info "Go version: $(/usr/local/go/bin/go version)"

            # Test compilation
            log_info "Testing Go compilation..."
            local temp_dir=$(mktemp -d)
            echo 'package main
import "fmt"
func main() { fmt.Println("Hello, Go!") }' > "$temp_dir/hello.go"

            if /usr/local/go/bin/go run "$temp_dir/hello.go" &>/dev/null; then
                log_info "Go compilation test passed!"
            else
                log_error "Go compilation test failed!"
                rm -rf "$temp_dir"
                return 1
            fi
            rm -rf "$temp_dir"
        else
            log_error "Go installation failed"
            return 1
        fi
    fi
}

# Function to install system dependencies
install_system_dependencies() {
    log_info "Installing system dependencies..."

    sudo nala update
    sudo nala install -y \
        wget \
        gnupg \
        apt-transport-https \
        ca-certificates \
        curl \
        lsb-release \
        unzip \
        git
}

# Function to install HashiCorp tools
install_hashicorp_tools() {
    log_info "Installing HashiCorp tools (Terraform, Packer, Vagrant)..."

    # Add HashiCorp GPG key
    wget -qO- https://apt.releases.hashicorp.com/gpg | \
        sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg || true

    # Add HashiCorp repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list

    sudo nala update
    sudo nala install -y terraform packer vagrant
}

# Function to install Kubernetes tools
install_kubernetes_tools() {
    log_info "Installing Kubernetes tools..."

    # Create keyrings directory
    sudo mkdir -p /etc/apt/keyrings

    # Install kubectl
    log_info "Installing kubectl..."
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
        sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg || true

    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | \
        sudo tee /etc/apt/sources.list.d/kubernetes.list

    sudo nala update
    sudo nala install -y kubectl

    # Install kind
    log_info "Installing kind..."
    if [ "$(uname -m)" = "x86_64" ]; then
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi

    # Install Helm
    log_info "Installing Helm..."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm -f get_helm.sh

    # Install k3d
    log_info "Installing k3d..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

# Function to install kubectl plugins
install_kubectl_plugins() {
    log_info "Installing kubectl plugins..."

    # Install krew (kubectl plugin manager)
    (
        set -x
        cd "$(mktemp -d)" &&
        OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
        ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
        KREW="krew-${OS}_${ARCH}" &&
        curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
        tar zxvf "${KREW}.tar.gz" &&
        ./"${KREW}" install krew
    )

    # Add krew to PATH if not already there
    if ! grep -q 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' ~/.bashrc; then
        echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc
    fi
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

    # Install useful kubectl plugins
    kubectl krew install ctx ns tree node-shell modify-secret cilium neat stern rook-ceph
}

# Function to install Go-based tools
install_go_tools() {
    log_info "Installing Go-based tools..."

    # Verify Go is available and working
    if ! command -v go &> /dev/null; then
        log_error "Go is not installed. Cannot install Go-based tools."
        return 1
    fi

    # Test Go installation with a more thorough check
    log_info "Verifying Go installation..."
    if ! go version &>/dev/null; then
        log_error "Go installation is corrupted. Please run the script again."
        return 1
    fi

    log_info "Go is working properly: $(go version)"

    # Clear any existing Go module cache issues
    log_info "Clearing Go module cache..."
    go clean -modcache 2>/dev/null || true

    # Set Go environment for this session if not set
    if [ -z "$GOPATH" ]; then
        export GOPATH=$HOME/go
        export GOROOT=/usr/local/go
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    fi

    # Install kubecolor
    log_info "Installing kubecolor..."
    if ! go install github.com/kubecolor/kubecolor@latest; then
        log_error "Failed to install kubecolor"
        return 1
    fi

    # Install k9s
    log_info "Installing k9s..."
    if ! go install github.com/derailed/k9s@latest; then
        log_error "Failed to install k9s"
        return 1
    fi

    # Verify installations
    if [ -f "$GOPATH/bin/kubecolor" ]; then
        log_info "kubecolor installed successfully"
    else
        log_warn "kubecolor binary not found in $GOPATH/bin"
    fi

    if [ -f "$GOPATH/bin/k9s" ]; then
        log_info "k9s installed successfully"
    else
        log_warn "k9s binary not found in $GOPATH/bin"
    fi

    log_info "Go-based tools installation completed"
}

# Main installation function
main() {
    log_info "Starting DevOps tools installation..."

    install_go
    install_system_dependencies
    install_hashicorp_tools
    install_kubernetes_tools
    install_kubectl_plugins
    install_go_tools

    log_info "Installation completed successfully!"
    log_warn "Please run 'source ~/.bashrc' or restart your terminal to apply PATH changes."

    # Display installed versions
    echo
    log_info "Installed tool versions:"
    echo "Go: $(go version 2>/dev/null || echo 'Not found')"
    echo "Terraform: $(terraform version 2>/dev/null | head -n1 || echo 'Not found')"
    echo "kubectl: $(kubectl version --client 2>/dev/null || echo 'Not found')"
    echo "Helm: $(helm version --short 2>/dev/null || echo 'Not found')"
}

# Run main function
main "$@"
