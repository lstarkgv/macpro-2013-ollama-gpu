#!/bin/bash

# Mac Pro 2013 - GPU Diagnostics Script for Ubuntu
# ------------------------------------------------

echo "========================================"
echo "Mac Pro 2013 - GPU Diagnostics"
echo "========================================"
echo ""

# 1. Check if rebooted after GRUB config
echo "[1] Checking kernel parameters..."
if cat /proc/cmdline | grep -q "amdgpu.si_support=1"; then
    echo "✅ GPU parameters are active in current boot"
else
    echo "❌ GPU parameters NOT found. You may need to reboot or check GRUB config."
    echo "   Current kernel cmdline: $(cat /proc/cmdline)"
fi
echo ""

# 2. Check which driver is actually loaded
echo "[2] Checking loaded GPU drivers..."
lspci -k | grep -A 3 -E "(VGA|3D)"
echo ""

# 3. Check for amdgpu device nodes
echo "[3] Checking for /dev/dri devices..."
if [ -e /dev/dri ]; then
    ls -la /dev/dri/
    echo "✅ /dev/dri exists"
else
    echo "❌ /dev/dri not found"
fi
echo ""

# 4. Check Vulkan availability
echo "[4] Checking Vulkan support..."
if command -v vulkaninfo &> /dev/null; then
    if vulkaninfo --summary &> /dev/null; then
        echo "✅ Vulkan is working"
        vulkaninfo --summary | grep -E "deviceName|driverVersion"
    else
        echo "❌ Vulkan command exists but reports errors"
        echo "   Try: vulkaninfo for full error details"
    fi
else
    echo "❌ vulkaninfo not found. Install with:"
    echo "   sudo apt install vulkan-tools"
fi
echo ""

# 5. Check Ollama service configuration
echo "[5] Checking Ollama systemd service..."
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama service is running"
    echo "   Environment variables:"
    systemctl show ollama | grep Environment || echo "   (No custom env vars found)"
else
    echo "❌ Ollama service is not running"
fi
echo ""

# 6. Check if OLLAMA_VULKAN is set
echo "[6] Checking OLLAMA_VULKAN environment variable..."
if systemctl show ollama | grep -q "OLLAMA_VULKAN=1"; then
    echo "✅ OLLAMA_VULKAN=1 is set in service"
else
    echo "❌ OLLAMA_VULKAN=1 is NOT set in service"
    echo ""
    echo "To fix this, edit the service:"
    echo "  sudo systemctl edit ollama"
    echo ""
    echo "Add this content:"
    echo "  [Service]"
    echo "  Environment=\"OLLAMA_VULKAN=1\""
    echo ""
    echo "Then restart:"
    echo "  sudo systemctl daemon-reload"
    echo "  sudo systemctl restart ollama"
fi
echo ""

# 7. Check for radeon vs amdgpu modules
echo "[7] Checking loaded kernel modules..."
if lsmod | grep -q "^amdgpu "; then
    echo "✅ amdgpu module is loaded"
else
    echo "❌ amdgpu module NOT loaded"
fi
if lsmod | grep -q "^radeon "; then
    echo "⚠️  radeon module is loaded (should be unloaded for amdgpu to work)"
else
    echo "✅ radeon module is NOT loaded (good)"
fi
echo ""

echo "========================================"
echo "Diagnostic complete"
echo "========================================"
