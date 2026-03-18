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

# Step 2: Install required packages
echo "[2/5] Installing required packages..."
apt install -y whiptail git curl docker.io docker-compose-v2 python3-pip

# Step 3: Enable and start Docker
echo "[3/5] Configuring Docker..."
systemctl enable docker
systemctl start docker

# Step 4: Install Vulkan support
echo "[4/5] Installing Vulkan support..."
apt install -y vulkan-tools mesa-vulkan-drivers vulkan-validationlayers

# Step 5: Configure GPU driver
echo "[5/5] Configuring GPU driver..."
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
