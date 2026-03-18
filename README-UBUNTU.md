# Mac Pro 2013 Ollama GPU - Ubuntu Server

Guía completa para habilitar aceleración GPU en Ollama para Mac Pro 2013 con AMD FirePro D700 en Ubuntu Server.

## Índice

1. [Requisitos Previos](#requisitos-previos)
2. [Guía Paso a Paso](#guía-paso-a-paso)
3. [Verificación del Sistema](#verificación-del-sistema)
4. [Solución de Problemas](#solución-de-problemas)
5. [Scripts Disponibles](#scripts-disponibles)

---

## Requisitos Previos

- Hardware: Mac Pro 2013 (6,1) con dual FirePro D700
- Sistema: Ubuntu Server 22.04 o 24.04
- Acceso: Usuario con permisos sudo
- Conexión: Internet para descargar paquetes

---

## Guía Paso a Paso

### PASO 1: Actualizar el sistema

```bash
sudo apt update && sudo apt upgrade -y
```

### PASO 2: Instalar dependencias necesarias

```bash
sudo apt install -y curl vulkan-tools mesa-vulkan-drivers wget
```

### PASO 3: Configurar el driver amdgpu en GRUB

**Este es el paso CRÍTICO.** Sin esto, las GPUs usarán el driver `radeon` sin Vulkan.

```bash
# 3a. Hacer backup de la configuración actual
sudo cp /etc/default/grub /etc/default/grub.backup

# 3b. Agregar los parámetros del kernel
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1radeon.si_support=0 amdgpu.si_support=1 "/' /etc/default/grub

# 3c. Verificar que se agregaron correctamente
cat /etc/default/grub | grep amdgpu
# Debe mostrar: radeon.si_support=0 amdgpu.si_support=1
```

### PASO 4: Actualizar GRUB

```bash
sudo update-grub
```

### PASO 5: REINICIAR (OBLIGATORIO)

```bash
sudo reboot
```

⚠️ **Los parámetros del kernel SOLO se aplican al reiniciar.** Sin reiniciar, el driver `radeon` seguirá activo.

### PASO 6: Verificar que amdgpu esté activo (después del reinicio)

```bash
# 6a. Verificar parámetros del kernel
cat /proc/cmdline | grep amdgpu
# Debe mostrar: radeon.si_support=0 amdgpu.si_support=1

# 6b. Verificar qué driver usa la GPU
lspci -k | grep -A 3 "VGA compatible"
# Debe mostrar: Kernel driver in use: amdgpu
# Si muestra "radeon", NO reiniciaste correctamente

# 6c. Verificar Vulkan
vulkaninfo --summary 2>&1 | head -20
# Debe mostrar dispositivos GPU, NO solo "llvmpipe"
```

### PASO 7: Instalar Ollama (si no lo tienes)

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### PASO 8: Configurar el servicio de Ollama para usar Vulkan

```bash
# Crear configuración de override
sudo mkdir -p /etc/systemd/system/ollama.service.d

# Crear archivo con variables de entorno
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << 'EOF'
[Service]
Environment="OLLAMA_VULKAN=1"
Environment="OLLAMA_HOST=0.0.0.0"
EOF

# Recargar y reiniciar el servicio
sudo systemctl daemon-reload
sudo systemctl restart ollama

# Verificar que el servicio esté corriendo
sudo systemctl status ollama
```

### PASO 9: Probar Ollama con GPU

```bash
# Descargar un modelo pequeño
ollama pull qwen3:8b

# Probar generación (monitorea uso de GPU en otra terminal)
ollama run qwen3:8b "Hola, ¿qué tal?"

# En otra terminal, verificar uso de GPU
sudo cat /sys/class/drm/card0/device/gpu_busy_percent
```

---

## Verificación del Sistema

### Ejecutar diagnóstico completo

```bash
chmod +x diagnose-ubuntu.sh
sudo bash diagnose-ubuntu.sh
```

### Verificaciones manuales

| Verificación | Comando | Resultado esperado |
|--------------|---------|-------------------|
| Parámetros kernel | `cat /proc/cmdline \| grep amdgpu` | `radeon.si_support=0 amdgpu.si_support=1` |
| Driver GPU | `lspci -k \| grep "Kernel driver"` | `amdgpu` |
| Vulkan | `vulkaninfo --summary` | Dispositivos GPU detectados |
| Ollama Vulkan | `systemctl show ollama \| grep OLLAMA_VULKAN` | `OLLAMA_VULKAN=1` |

---

## Solución de Problemas

### Problema: "Kernel driver in use: radeon" (después de reiniciar)

**Causa:** Los parámetros no se agregaron correctamente a GRUB.

**Solución:**
```bash
# Verificar /etc/default/grub
cat /etc/default/grub | grep GRUB_CMDLINE_LINUX_DEFAULT

# Si no tiene los parámetros, agrégalo manualmente
sudo nano /etc/default/grub
# Edita la línea GRUB_CMDLINE_LINUX_DEFAULT para que incluya:
# GRUB_CMDLINE_LINUX_DEFAULT="radeon.si_support=0 amdgpu.si_support=1"

# Luego actualiza y reinicia
sudo update-grub
sudo reboot
```

### Problema: Vulkan muestra "llvmpipe" (software rendering)

**Causa:** Vulkan no detecta las GPUs porque usan el driver radeon.

**Solución:**
```bash
# 1. Verificar que amdgpu esté cargado
lsmod | grep amdgpu

# 2. Si no está cargado, verificar módulos
sudo modprobe amdgpu

# 3. Si el problema persiste, reinstalar drivers Vulkan
sudo apt install --reinstall -y mesa-vulkan-drivers
```

### Problema: Ollama no usa la GPU (CPU lento)

**Causa:** Falta la variable de entorno OLLAMA_VULKAN=1.

**Solución:**
```bash
# Ejecutar script de corrección
chmod +x fix-ollama-service.sh
sudo bash fix-ollama-service.sh

# O manual:
sudo systemctl edit ollama
# Agregar:
# [Service]
# Environment="OLLAMA_VULKAN=1"
```

### Problema: Error de containerd al instalar Docker

**Causa:** Ubuntu Server incluye containerd nativo que entra en conflicto.

**Solución:**
```bash
# Usar script que maneja esto automáticamente
chmod +x install-ubuntu.sh
sudo bash install-ubuntu.sh

# O resolver manualmente
sudo apt remove containerd
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### Problema: ¿Reinicié pero aún usa radeon?

```bash
# Verificar si GRUB se actualizó correctamente
sudo ls -la /boot/grub/grub.cfg
# Ver la fecha del archivo

# Forzar actualización de GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo reboot
```

---

## Scripts Disponibles

| Script | Propósito | Cuándo usarlo |
|--------|-----------|---------------|
| `install-ubuntu.sh` | Instalación completa | Instalación desde cero |
| `install-ubuntu-no-docker.sh` | Solo GPU+Vulkan | Si ya tienes Docker |
| `setup-gpu-ubuntu.sh` | Configurar GRUB | Para configurar driver amdgpu |
| `fix-grub-reboot.sh` | Verificar y corregir GRUB | Si el driver no cambió |
| `diagnose-ubuntu.sh` | Diagnóstico completo | Para verificar estado del sistema |
| `fix-ollama-service.sh` | Configurar servicio Ollama | Si Ollama no usa GPU |
| `tui-ubuntu.sh` | Interfaz interactiva | Para usar menús gráficos |

---

## Rendimiento Esperado

Después de la configuración correcta:

| Modelo | Prompt (tok/s) | Generación (tok/s) |
|--------|----------------|-------------------|
| qwen3:8b | ~46 | ~18 |
| qwen2.5-coder:14b | ~43 | ~11.5 |
| codellama:13b | ~35 | ~10 |

**Sin GPU (CPU only):** <2 tok/s

---

## Resumen Rápido

```bash
# 1. Instalar dependencias
sudo apt update && sudo apt install -y vulkan-tools mesa-vulkan-drivers curl

# 2. Configurar GRUB
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="radeon.si_support=0 amdgpu.si_support=1 /' /etc/default/grub
sudo update-grub

# 3. REINICIAR (crítico)
sudo reboot

# 4. Después del reinicio - verificar
lspci -k | grep "Kernel driver"  # Debe decir amdgpu

# 5. Instalar y configurar Ollama
curl -fsSL https://ollama.com/install.sh | sh
sudo mkdir -p /etc/systemd/system/ollama.service.d
echo -e "[Service]\nEnvironment=\"OLLAMA_VULKAN=1\"" | sudo tee /etc/systemd/system/ollama.service.d/override.conf
sudo systemctl daemon-reload && sudo systemctl restart ollama

# 6. Probar
ollama run qwen3:8b "Hola"
```

---

## Soporte

Si encuentras problemas:

1. Ejecuta `sudo bash diagnose-ubuntu.sh` y comparte la salida
2. Verifica que hayas reiniciado después de configurar GRUB
3. Confirma que `lspci -k` muestra `amdgpu` y NO `radeon`
