#!/bin/bash

# Fix Ollama Service to use Vulkan GPU
# ------------------------------------

set -e

echo "Fixing Ollama service for GPU acceleration..."

# Create override directory
mkdir -p /etc/systemd/system/ollama.service.d

# Create override file with Vulkan environment variable
cat > /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_VULKAN=1"
Environment="OLLAMA_DEBUG=1"
EOF

echo "✅ Override file created at /etc/systemd/system/ollama.service.d/override.conf"

# Reload systemd and restart service
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Restarting Ollama service..."
systemctl restart ollama

echo ""
echo "✅ Done! Ollama service now has OLLAMA_VULKAN=1 enabled."
echo ""
echo "Verify GPU is being used with:"
echo "  sudo journalctl -u ollama -n 50 | grep -i vulkan"
echo ""
echo "Or run a model and check for GPU usage:"
echo "  ollama run qwen3:8b"
echo "  # In another terminal: sudo watch -n 1 cat /proc/loadavg"
echo "  # Or check GPU with: sudo cat /sys/kernel/debug/vk/amdgpu/../../gpu utilization"
