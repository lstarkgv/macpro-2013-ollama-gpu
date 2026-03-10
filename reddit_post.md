# [Guide] Full GPU Acceleration for Ollama on Mac Pro 2013 (Dual FirePro D700) - Linux

Hey everyone! I finally managed to get full GPU acceleration working for **Ollama** on the legendary **Mac Pro 6.1 (2013 "Trashcan")** running Nobara Linux (and it should work on other distros too).

The problem with these machines is that they have dual **AMD FirePro D700s (Tahiti XT)**. By default, Linux uses the legacy `radeon` driver for these cards. While `radeon` works for display, it **does not support Vulkan or ROCm**, meaning Ollama defaults to the CPU, which is slow as molasses.

### My Setup:
- **Model:** Mac Pro 6,1 (Late 2013)
- **CPU:** Xeon E5-1680 v2 (8C/16T @ 3.0 GHz)
- **RAM:** 32GB
- **GPU:** Dual AMD FirePro D700 (6GB each, 12GB total VRAM)
- **OS:** Nobara Linux (Fedora 40/41 base)

### The Solution:
We need to force the `amdgpu` driver for the Southern Islands (SI) architecture. Once `amdgpu` is active, Vulkan is enabled, and Ollama picks up both GPUs automatically!

### Performance (The Proof):
I'm currently testing **`qwen2.5-coder:14b`** (9GB model). 
- **GPU Offload:** 100% (49/49 layers)
- **VRAM Split:** Perfectly balanced across both D700s (~4GB each)
- **Speed:** **~11.5 tokens/second** 🚀
- **Total Response Time:** ~13.8 seconds for a standard coding prompt.

On CPU alone, this model was barely usable at <2 tokens/sec. This fix makes the Trashcan a viable local LLM workstation in 2026!

### How to do it:

**1. Update Kernel Parameters**
Add these to your GRUB configuration:
`radeon.si_support=0 amdgpu.si_support=1`

On Fedora/Nobara:
```bash
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="radeon.si_support=0 amdgpu.si_support=1 /' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
```

**2. Reboot**
`sudo reboot`

**3. Container Config (Crucial!)**
If you're running Ollama in a container (Podman or Docker), you MUST:
- Pass `/dev/dri` to the container.
- Set `OLLAMA_VULKAN=1`.
- Disable security labels (SecurityLabel=disable in Quadlet).

**Result:**
My D700s are now identified as **Vulkan0** and **Vulkan1** in Ollama logs, and they split the model VRAM perfectly! 🚀

I've put together a GitHub-ready folder with scripts and configs here: [Link to your repo]

Hope this helps any fellow Trashcan owners out there trying to run local LLMs!

#MacPro #Linux #Ollama #SelfHosted #AMD #FireProD700
