#!/bin/bash

# Mac Pro 2013 - Verify and Fix GRUB + Reboot
# -------------------------------------------

set -e

echo "========================================"
echo "Mac Pro 2013 - GRUB Verification & Fix"
echo "========================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo:"
    echo "sudo bash $0"
    exit 1
fi

# Check current GRUB config
echo "[1] Checking /etc/default/grub..."
if grep -q "amdgpu.si_support=1" /etc/default/grub; then
    echo "✅ Parameters already in /etc/default/grub"
    echo "Content:"
    grep "GRUB_CMDLINE_LINUX" /etc/default/grub
else
    echo "❌ Parameters NOT in /etc/default/grub. Adding now..."
    cp /etc/default/grub /etc/default/grub.bak-$(date +%Y%m%d-%H%M%S)

    if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=" /etc/default/grub; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1radeon.si_support=0 amdgpu.si_support=1 "/' /etc/default/grub
    else
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="radeon.si_support=0 amdgpu.si_support=1"' >> /etc/default/grub
    fi

    echo "✅ Parameters added to /etc/default/grub"
    echo "New content:"
    grep "GRUB_CMDLINE_LINUX" /etc/default/grub
fi

echo ""
echo "[2] Updating GRUB configuration..."
update-grub

echo ""
echo "========================================"
echo "✅ GRUB configuration updated!"
echo "========================================"
echo ""
echo "⚠️  IMPORTANT: You MUST reboot for changes to take effect."
echo ""
echo "After reboot, verify with:"
echo "  cat /proc/cmdline | grep amdgpu"
echo "  lspci -k | grep -A 3 VGA"
echo ""
echo "The 'Kernel driver in use' should show 'amdgpu' NOT 'radeon'"
echo ""

read -p "Reboot now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    reboot
else
    echo "Remember to reboot manually: sudo reboot"
fi
