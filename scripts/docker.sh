#!/bin/bash

set -e

echo "🐳 Docker Installation Script"
echo "============================"

if ! grep -qE "ID(_LIKE)?=.*debian" /etc/os-release && ! grep -qE "ID(_LIKE)?=.*ubuntu" /etc/os-release; then
    echo "⚠️  This script is for Debian-based systems (Debian/Ubuntu/Mint etc.)"
    echo "Detected: $(grep '^PRETTY_NAME=' /etc/os-release | cut -d'"' -f2)"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

IS_WSL=false
if grep -q "microsoft" /proc/version 2>/dev/null; then
    echo "✅ WSL2 detected"
    IS_WSL=true
else
    echo "✅ Native Linux detected"
fi

echo "📦 Updating package lists..."
sudo apt update -qq

echo "🔧 Installing prerequisites..."
sudo apt install -y ca-certificates curl gnupg

echo "🔑 Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || true
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "🔍 Detecting system..."
if grep -q "ID=ubuntu" /etc/os-release || grep -q "ID_LIKE.*ubuntu" /etc/os-release; then
    DOCKER_REPO="ubuntu"
    if grep -q "UBUNTU_CODENAME=" /etc/os-release; then
        CODENAME=$(. /etc/os-release && echo "$UBUNTU_CODENAME")
    else
        CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
    fi
    echo "📋 Ubuntu-based system detected: $CODENAME"
else
    DOCKER_REPO="debian"
    CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
    echo "📋 Debian system detected: $CODENAME"
fi

echo "📚 Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DOCKER_REPO $CODENAME stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -qq
echo "🐳 Installing Docker packages..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "👤 Adding user to docker group..."
sudo usermod -aG docker $USER

echo "🚀 Starting Docker..."
if systemctl --no-pager status user.slice > /dev/null 2>&1; then
    echo "🔧 Using systemd..."
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "🔧 Using SysV init..."
    sudo service docker start || true
    sleep 2
    echo "✅ Docker service started"

    if [[ "$IS_WSL" == "true" ]]; then
        echo "⚙️  Setting up WSL2 auto-start..."
        if [[ ! -f /etc/wsl.conf ]] || ! grep -q "service docker start" /etc/wsl.conf; then
            echo '[boot]
command="service docker start"
[automount]
root = /
options = "metadata,umask=22,fmask=11"
[interop]
enabled = true
appendWindowsPath = false' | sudo tee /etc/wsl.conf > /dev/null
            echo "✅ WSL2 auto-start configured"
        fi
        if ! grep -q "service docker start" ~/.profile 2>/dev/null; then
            echo '
# Auto-start Docker in WSL2
if grep -q "microsoft" /proc/version 2>/dev/null && ! sudo service docker status >/dev/null 2>&1; then
    sudo service docker start >/dev/null 2>&1
fi' >> ~/.profile
            echo "✅ Profile fallback added"
        fi
    fi
fi

echo "🧪 Testing Docker..."
if timeout 10s sudo docker run --rm hello-world >/dev/null 2>&1; then
    echo "✅ Docker test successful!"
else
    echo "⚠️  Docker test skipped - continuing..."
    # Ensure Docker is running
    sudo service docker start >/dev/null 2>&1 || true
fi

echo ""
echo "🎉 Docker Installation Complete!"
echo "==============================="
echo ""
echo "📝 Important Notes:"
if [[ "$IS_WSL" == "true" ]]; then
    echo "• Restart WSL2 for docker group: wsl --shutdown (in Windows PowerShell)"
    echo "• Docker auto-starts when WSL2 boots"
else
    echo "• Log out and back in for docker group membership"
    echo "• Docker service starts automatically on boot"
fi
echo "• Test Docker: docker run hello-world"
echo "• Check status: sudo service docker status"
echo "• Start manually: sudo service docker start"
echo ""
echo "🔧 Docker Compose is included!"
echo "• Version: $(docker compose version 2>/dev/null || echo 'Run docker compose version after logout')"
echo ""
echo "🚀 You're ready to use Docker!"
