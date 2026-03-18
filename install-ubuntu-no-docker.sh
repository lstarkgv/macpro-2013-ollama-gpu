#!/bin/bash

# Mac Pro 2013 - Ubuntu Server Quick Install (Skip Docker)
# --------------------------------------------------------
# This script only installs Vulkan support and configures GPU driver.
# Use this if you already have Docker installed.

set -e

echo "========================================"
echo "Mac Pro 2013 - Ubuntu Quick Install"
echo "(Skipping Docker installation)"
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "sudo bash $0"
    exit 1
fi

# Step 1: Update package list
echo "[1/3] Updating package list..."
apt update

# Step 2: Install Vulkan support
echo "[2/3] Installing Vulkan support..."
apt install -y vulkan-tools mesa-vulkan-drivers vulkan-validationlayers

# Step 3: Configure GPU driver
echo "[3/3] Configuring GPU driver..."
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
echo "Setup Complete!"
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
