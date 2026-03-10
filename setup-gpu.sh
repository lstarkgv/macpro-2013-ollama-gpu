#!/bin/bash

# Mac Pro 2013 GPU Setup Script for Ollama
# ----------------------------------------
# This script automates the transition from the 'radeon' driver to 'amdgpu'
# for the dual FirePro D700 (Tahiti) GPUs found in the Mac Pro 6,1.
# 
# Why? The 'radeon' driver lacks Vulkan support for these cards, which Ollama
# needs for GPU acceleration. 'amdgpu' enables Vulkan and unlocks the GPU.

set -e

echo "----------------------------------------------------"
echo "🚀 Mac Pro 2013 GPU Setup: Enabling Ollama acceleration"
echo "----------------------------------------------------"

# 1. Check if parameters are already present in the GRUB configuration
# We need radeon.si_support=0 to stop the old driver from claiming the card,
# and amdgpu.si_support=1 to tell the new driver to take it over.
if grep -q "amdgpu.si_support=1" /etc/default/grub; then
    echo "✅ Kernel parameters already present in /etc/default/grub."
else
    echo "📝 Adding kernel parameters to /etc/default/grub..."
    
    # Backup the original configuration file before making changes
    sudo cp /etc/default/grub /etc/default/grub.bak
    echo "   (Backup created at /etc/default/grub.bak)"
    
    # Use sed to inject the parameters into the GRUB_CMDLINE_LINUX_DEFAULT string.
    # This affects the boot arguments passed to the kernel.
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="radeon.si_support=0 amdgpu.si_support=1 /' /etc/default/grub
    echo "✅ Parameters added to GRUB configuration."
fi

# 2. Regenerate the GRUB configuration file
# This updates the actual boot menu entries used by the system.
echo "🔄 Regenerating GRUB configuration (this may take a moment)..."

# Detect the correct path for grub.cfg based on common Fedora/Nobara locations
if [ -f /boot/grub2/grub.cfg ]; then
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
elif [ -f /boot/efi/EFI/fedora/grub.cfg ]; then
    # Some UEFI systems use this path instead
    sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
else
    echo "❌ ERROR: Could not find grub.cfg path. Please run grub-mkconfig manually."
    exit 1
fi

echo "----------------------------------------------------"
echo "🎉 Setup complete! "
echo "A reboot is REQUIRED to activate the amdgpu driver."
echo "----------------------------------------------------"
echo "Reboot command: sudo reboot"
