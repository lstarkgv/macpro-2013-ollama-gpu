# [Guide] Full GPU Acceleration for Ollama on Mac Pro 2013 (Dual FirePro D700) - Linux

Hey everyone! I finally managed to get full GPU acceleration working for **Ollama** on the legendary **Mac Pro 6.1 (2013 "Trashcan")** running Nobara Linux (and it should work on other distros too).

The problem with these machines is that they have dual **AMD FirePro D700s (Tahiti XT)**. By default, Linux uses the legacy `radeon` driver for these cards. While `radeon` works for display, it **does not support Vulkan or ROCm**, meaning Ollama defaults to the CPU, which is slow as molasses.

### My Setup:
- **Model:** Mac Pro 6,1 (Late 2013)
- **CPU:** Xeon E5-1680 v2 (8C/16T @ 3.0 GHz)
- **RAM:** 32GB
- **GPU:** Dual AMD FirePro D700 (6GB each, 12GB total VRAM)
- **OS:** Nobara Linux (Fedora 40/41 base)
- **Ollama:** 0.17.0 — **native install** (no Docker/Podman needed!)

### The Solution:
Force the `amdgpu` driver for the Southern Islands (SI) architecture. Once `amdgpu` is active, Vulkan is enabled, and Ollama picks up both GPUs automatically!

### Updated Performance Benchmarks:

**qwen3:8b** (4.9 GB model):
- GPU Offload: 100%
- VRAM: ~5.9 GB split across both D700s
- Speed: **~16–18 tokens/second**

**qwen2.5-coder:14b** (9 GB model):
- GPU Offload: 100% (49/49 layers)
- VRAM: ~4.1 GB per GPU
- Speed: **~11.5 tokens/second**

On CPU alone, these models run at <2 tok/sec. This fix makes the Trashcan a genuinely useful local LLM workstation in 2026!

### How to do it:

**1. Update Kernel Parameters**

Add these to your GRUB configuration (`/etc/default/grub`):
```
radeon.si_support=0 amdgpu.si_support=1
```

On Fedora/Nobara, or just use the script in the repo:
```bash
sudo bash setup-gpu.sh
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo reboot
```

**2. Install Ollama Natively**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**3. Add OLLAMA_VULKAN=1 to the systemd service**

Edit `/etc/systemd/system/ollama.service` and add:
```
Environment="OLLAMA_VULKAN=1"
```

Then:
```bash
sudo systemctl daemon-reload && sudo systemctl restart ollama
```

**4. Verify**
```bash
lspci -k | grep -A 3 -E "(VGA|3D)"
# Should show: Kernel driver in use: amdgpu

ollama ps
# Should show: 100% GPU
```

The D700s show up as **Vulkan0** and **Vulkan1** in Ollama logs — both GPUs fully utilized.

If you prefer Docker/Podman containers, I've got configs for that too — see the repo for `ollama.container` (Podman Quadlet) and `docker-compose.yml`.

Full repo with scripts, configs, and TUI: https://github.com/manu7irl/macpro-2013-ollama-gpu

Hope this helps any fellow Trashcan owners out there!

#MacPro #Linux #Ollama #SelfHosted #AMD #FireProD700 #LocalLLM
