# Mac Pro 2013 (Trashcan) Ollama GPU Acceleration Fix

This repository provides the configuration and scripts to enable full GPU acceleration for **Ollama** on a **Mac Pro 6.1 (2013)** running **Nobara Linux** (or any Fedora/RHEL-based distro). 

The Mac Pro 2013 features dual **AMD FirePro D700 (Tahiti XT)** GPUs. By default, Linux uses the `radeon` driver for these cards, which does not support Vulkan or ROCm, leaving Ollama to run on the CPU only.

This fix forces the `amdgpu` driver, which enables Vulkan support and allows Ollama to utilize both GPUs.

## 💻 Hardware Profile (The "Trashcan")

This configuration is optimized for the following high-spec Mac Pro 6,1 setup:
- **CPU:** Intel Xeon E5-1680 v2 (8 Cores / 16 Threads @ 3.0 GHz)
- **RAM:** 32 GB DDR3 ECC
- **GPUs:** 2x AMD FirePro D700 (6GB GDDR5 VRAM each, total 12GB VRAM)
- **Architecture:** Tahiti XT (GCN 1.0 / Southern Islands)
- **OS:** Nobara Linux (Optimized Fedora-based distro)

With this fix, Ollama can split models across both GPUs, providing 12GB of total VRAM for inference.

## 📊 Benchmarks & Performance

**Active Model:** `qwen2.5-coder:14b` (9.0 GB)

| Metric | Result |
|--------|--------|
| **GPU Offloading** | 49/49 layers (100% GPU) |
| **VRAM Usage** | ~4.1GB on GPU 0, ~4.1GB on GPU 1 |
| **Response Speed** | **~11.5 tokens/sec** |
| **Total Duration** | ~13.8s (for 150+ tokens) |

*The dual FirePro D700 setup effectively doubles the available VRAM and significantly outperforms CPU-only inference, which typically struggles at <2 tok/sec for a 14B model.*

## 🚀 The Fix at a Glance

1. **Kernel Parameters:** Disable `radeon` SI support and enable `amdgpu` SI support.
2. **GRUB Update:** Persist these changes in the bootloader.
3. **Container Config:** Pass the DRI devices to the Ollama container and force Vulkan.

---

## 🛠️ Step-by-Step Instructions

### 1. Update Kernel Parameters
You need to add `radeon.si_support=0 amdgpu.si_support=1` to your kernel command line.

**Edit `/etc/default/grub`:**
Find the line starting with `GRUB_CMDLINE_LINUX_DEFAULT` and append the parameters:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="... radeon.si_support=0 amdgpu.si_support=1"
```

**Regenerate GRUB configuration:**
```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### 2. Reboot
Reboot your system to apply the new driver configuration:
```bash
sudo reboot
```

### 3. Verify Driver
After rebooting, verify that the `amdgpu` driver is in use:
```bash
lspci -k | grep -A 3 -E "(VGA|3D)"
```
You should see `Kernel driver in use: amdgpu`.

### 4. Deploy Ollama with GPU Support
Use the provided `ollama.container` (for Podman Quadlet) or the `docker-compose.yml`.

**Key requirements:**
- Mount `/dev/dri` to the container.
- Set `OLLAMA_VULKAN=1` environment variable.
- Disable security labels (if using SELinux/AppArmor) to allow device access.

---

## 📂 Repository Structure

- `setup-gpu.sh`: An automated script to apply kernel changes.
- `tui.sh`: A guided Terminal User Interface (TUI) for the setup.
- `ollama.container`: Podman Quadlet configuration.
- `docker-compose.yml`: Standard Docker Compose configuration.

## 🤝 Community
Inspired by the Mac Pro 2013 enthusiast community. If you found this helpful, share it on Reddit or GitHub!

---
*Note: This configuration was tested on Nobara Linux 43 with Kernel 6.18+.*
