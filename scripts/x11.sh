#!/bin/bash

# X11 Dependencies Installation Script for WSL2/Debian
# This script installs all necessary X11 libraries for GUI applications like Alacritty
# cargo install alacritty --no-default-features --features="x11"

set -e

echo "Installing X11 dependencies for GUI applications..."

# Update package list
echo "Updating package list..."
sudo apt update

# Core X11 libraries
echo "Installing core X11 libraries..."
sudo apt install -y \
    libx11-6 \
    libx11-dev \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libxrandr2 \
    libxcursor1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxss1 \
    libxinerama1

# XKB (X Keyboard) libraries - essential for Alacritty
echo "Installing XKB libraries..."
sudo apt install -y \
    libxkbcommon0 \
    libxkbcommon-x11-0 \
    libxkbcommon-dev \
    libxkbcommon-x11-dev

# XCB libraries (X protocol C-language Binding)
echo "Installing XCB libraries..."
sudo apt install -y \
    libxcb1 \
    libxcb1-dev \
    libxcb-xfixes0-dev \
    libxcb-render0-dev \
    libxcb-shape0-dev \
    libxcb-shm0-dev

# OpenGL/Mesa libraries
echo "Installing OpenGL/Mesa libraries..."
sudo apt install -y \
    libgl1-mesa-dev \
    libgl1-mesa-glx \
    libglu1-mesa-dev \
    libegl1-mesa \
    libgles2-mesa-dev

# FontConfig libraries (for font handling)
echo "Installing FontConfig libraries..."
sudo apt install -y \
    libfontconfig1 \
    libfontconfig1-dev \
    libfreetype6 \
    libfreetype6-dev

# Additional useful libraries
echo "Installing additional GUI libraries..."
sudo apt install -y \
    libgconf-2-4 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    libcairo2 \
    libpango-1.0-0 \
    libatk1.0-0 \
    libgtk
