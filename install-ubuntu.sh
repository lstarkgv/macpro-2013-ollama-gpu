#!/bin/bash

# Mac Pro 2013 - Ubuntu Server Complete Installation Script
# --------------------------------------------------------
# This script handles the complete setup for Ollama GPU acceleration
# on Ubuntu Server for Mac Pro 2013 with dual FirePro D700s.

set -e

echo "========================================"
echo "Mac Pro 2013 - Ubuntu Server Installer"
echo "Ollama GPU Acceleration Setup"
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "sudo bash $0"
    exit 1
fi

# Step 1: Update package list
echo "[1/5] Updating package list..."
apt update

# Step 2: Remove conflicting containerd
echo "[2/6] Removing conflicting containerd (if present)..."
apt remove -y containerd || true

# Step 3: Install Docker from official repository
echo "[3/6] Installing Docker from official repository..."
# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 4: Enable and start Docker
echo "[4/6] Configuring Docker..."
systemctl enable docker
systemctl start docker

# Step 5: Install Vulkan support
echo "[5/6] Installing Vulkan support..."
apt install -y vulkan-tools mesa-vulkan-drivers vulkan-validationlayers

# Step 6: Configure GPU driver
echo "[6/6] Configuring GPU driver..."
if grep -q "amdgpu.si_support=1" /etc/default/grub; then
    echo "GPU parameters already configured in GRUB."
else
    echo "Adding GPU parameters to GRUB..."
    cp /etc/default/grub /etc/default/grub.bak
    if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1radeon.si_support=0 amdgpu.si_support=1 "/' /etc/default/grub
    else
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="radeon.si_support=0 amdgpu.si_support=1"' >> /etc/default/grub
    fi
    update-grub
fi

echo ""
echo "========================================"
echo "Installation Complete!"
echo "========================================"
echo ""
echo "IMPORTANT: You MUST reboot for changes to take effect."
echo ""
echo "After reboot, verify GPU setup with:"
echo "  vulkaninfo --summary"
echo ""
echo "Then start Ollama with:"
echo "  docker compose up -d"
echo ""
echo "Reboot now? (y/n)"
read -r answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    reboot
fi
