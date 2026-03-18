#!/bin/bash

# Mac Pro 2013 GPU Setup Script for Ollama - Ubuntu Server Edition
# ---------------------------------------------------------------
# This script automates the transition from the 'radeon' driver to 'amdgpu'
# for the dual FirePro D700 (Tahiti) GPUs found in the Mac Pro 6,1.
#
# Adapted for Ubuntu Server - uses update-grub instead of grub2-mkconfig
#
# Why? The 'radeon' driver lacks Vulkan support for these cards, which Ollama
# needs for GPU acceleration. 'amdgpu' enables Vulkan and unlocks the GPU.

set -e

echo "----------------------------------------------------"
echo "Mac Pro 2013 GPU Setup: Ubuntu Server Edition"
echo "Enabling Ollama GPU acceleration"
echo "----------------------------------------------------"

# 1. Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo:"
    echo "sudo bash $0"
    exit 1
fi

# 2. Check if parameters are already present in the GRUB configuration
if grep -q "amdgpu.si_support=1" /etc/default/grub; then
    echo "Kernel parameters already present in /etc/default/grub."
else
    echo "Adding kernel parameters to /etc/default/grub..."

    # Backup the original configuration file before making changes
    cp /etc/default/grub /etc/default/grub.bak
    echo "(Backup created at /etc/default/grub.bak)"

    # Use sed to inject the parameters into the GRUB_CMDLINE_LINUX_DEFAULT string.
    # First check if GRUB_CMDLINE_LINUX_DEFAULT exists, if not create it
    if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1radeon.si_support=0 amdgpu.si_support=1 "/' /etc/default/grub
    else
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="radeon.si_support=0 amdgpu.si_support=1"' >> /etc/default/grub
    fi
    echo "Parameters added to GRUB configuration."
fi

# 3. Update GRUB configuration using Ubuntu's update-grub
echo "Regenerating GRUB configuration (this may take a moment)..."

if command -v update-grub &> /dev/null; then
    update-grub
else
    echo "ERROR: update-grub not found. Trying grub-mkconfig directly..."
    grub-mkconfig -o /boot/grub/grub.cfg
fi

echo "----------------------------------------------------"
echo "Setup complete!"
echo "A reboot is REQUIRED to activate the amdgpu driver."
echo "----------------------------------------------------"
echo "Reboot command: sudo reboot"
