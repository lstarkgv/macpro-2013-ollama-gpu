# Mac Pro 2013 (Trashcan) Ollama GPU Acceleration Fix

This repository provides the configuration and scripts to enable full GPU acceleration for **Ollama** on a **Mac Pro 6.1 (2013)** running **Nobara Linux** (or any Fedora/RHEL-based distro).

The Mac Pro 2013 features dual **AMD FirePro D700 (Tahiti XT)** GPUs. By default, Linux uses the `radeon` driver for these cards, which does not support Vulkan or ROCm, leaving Ollama to run on the CPU only.

This fix forces the `amdgpu` driver, which enables Vulkan support and allows Ollama to utilize both GPUs — whether you run Ollama **natively** or **in a container**.

## 💻 Hardware Profile (The "Trashcan")

- **CPU:** Intel Xeon E5-1680 v2 (8 Cores / 16 Threads @ 3.0 GHz)
- **RAM:** 32 GB DDR3 ECC
- **GPUs:** 2x AMD FirePro D700 (6GB GDDR5 VRAM each, total 12GB VRAM)
- **Architecture:** Tahiti XT (GCN 1.0 / Southern Islands)
- **OS:** Nobara Linux (Optimized Fedora-based distro)
- **Ollama Version:** 0.17.0 (native install)

---

## 📊 Benchmarks & Performance

All benchmarks run with Ollama installed natively, `OLLAMA_VULKAN=1`, dual FirePro D700s active.

### qwen3:8b (4.9 GB)

| Metric | Result |
|--------|--------|
| **GPU Offloading** | 100% GPU |
| **VRAM Usage** | ~5.9 GB (split across both D700s) |
| **Tokens/sec** | **~16–18 tok/sec** |
| **Total duration (150 tok)** | ~9.5s |
| **Load time** | ~5.9s (cold start) |

### qwen2.5-coder:14b (9.0 GB) — Previous Benchmark

| Metric | Result |
|--------|--------|
| **GPU Offloading** | 49/49 layers (100% GPU) |
| **VRAM Usage** | ~4.1GB on GPU 0, ~4.1GB on GPU 1 |
| **Tokens/sec** | **~11.5 tok/sec** |
| **Total duration** | ~13.8s (150+ tokens) |

*On CPU alone, 14B models run at <2 tok/sec. This fix makes the Trashcan a viable local LLM workstation in 2026.*

---

## 🚀 The Fix at a Glance

1. **Kernel Parameters:** Disable `radeon` SI support and enable `amdgpu` SI support.
2. **GRUB Update:** Persist these changes in the bootloader.
3. **Ollama Config:** Set `OLLAMA_VULKAN=1` — either in the systemd service (native) or as a container environment variable.

---

## 🛠️ Step-by-Step: Native Install (Recommended)

### 1. Update Kernel Parameters

Add `radeon.si_support=0 amdgpu.si_support=1` to your kernel command line.

**Edit `/etc/default/grub`** — find `GRUB_CMDLINE_LINUX_DEFAULT` and append:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="... radeon.si_support=0 amdgpu.si_support=1"
```

Or run the automated script:
```bash
sudo bash setup-gpu.sh
```

**Regenerate GRUB:**
```bash
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

### 2. Reboot
```bash
sudo reboot
```

### 3. Verify Driver
```bash
lspci -k | grep -A 3 -E "(VGA|3D)"
# Should show: Kernel driver in use: amdgpu
```

### 4. Install Ollama Natively

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### 5. Configure the Systemd Service

Edit `/etc/systemd/system/ollama.service` to add `OLLAMA_VULKAN=1`:

```ini
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_ORIGINS=*"
Environment="OLLAMA_VULKAN=1"

[Install]
WantedBy=default.target
```

Apply and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now ollama
```

### 6. Verify GPU is Active
```bash
ollama run qwen3:8b "hello"
# Check logs:
journalctl -u ollama -f
# Look for: Vulkan0, Vulkan1 in the output
```

---

## 🐳 Alternative: Container Deploy (Docker / Podman)

If you prefer a containerized setup, use the provided configs.

### Podman Quadlet

Copy `ollama.container` to `/etc/containers/systemd/`:
```bash
sudo cp ollama.container /etc/containers/systemd/
sudo systemctl daemon-reload
sudo systemctl start ollama
```

### Docker Compose
```bash
docker compose up -d
```

**Key requirements for containers:**
- Mount `/dev/dri` to the container.
- Set `OLLAMA_VULKAN=1` environment variable.
- Disable security labels (`SecurityLabel=disable` in Quadlet / `--security-opt label=disable` in Docker).

---

## 📂 Repository Structure

| File | Purpose |
|------|---------|
| `setup-gpu.sh` | Automated script to apply kernel parameter changes |
| `tui.sh` | Guided Terminal UI for the setup |
| `ollama.container` | Podman Quadlet config (containerized) |
| `docker-compose.yml` | Docker Compose config (containerized) |

---

## 🤝 Community

Inspired by the Mac Pro 2013 enthusiast community. If you found this helpful, share it on Reddit or GitHub!

---

*Tested on Nobara Linux 43 with Kernel 6.18+, Ollama 0.17.0.*
