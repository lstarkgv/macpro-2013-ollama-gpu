# Mac Pro 2013 Ollama GPU - Ubuntu Server

Configuración para habilitar aceleración GPU en Ollama para Mac Pro 2013 con AMD FirePro D700 en Ubuntu Server.

## Requisitos Previos

- Mac Pro 2013 (6,1) con dual FirePro D700
- Ubuntu Server 22.04 o 24.04
- Acceso sudo

## Instalación

### Opción A: Instalación completa (recomendado)

Si no tienes Docker instalado o tienes problemas con `containerd`:

```bash
chmod +x install-ubuntu.sh
sudo bash install-ubuntu.sh
```

Este script:
- Elimina el `containerd` nativo que causa conflictos
- Instala Docker desde el repositorio oficial
- Configura Vulkan y el driver amdgpu

### Opción B: Solo configuración GPU (si ya tienes Docker)

```bash
chmod +x install-ubuntu-no-docker.sh
sudo bash install-ubuntu-no-docker.sh
```

### Opción C: Configuración manual

```bash
# 1. Instalar dependencias
sudo apt update
sudo apt install -y whiptail git vulkan-tools mesa-vulkan-drivers

# 2. Habilitar el driver amdgpu
chmod +x setup-gpu-ubuntu.sh
sudo bash setup-gpu-ubuntu.sh
```

### 3. Reiniciar

```bash
sudo reboot
```

### 4. Verificar que Vulkan esté disponible

```bash
# Instalar herramientas Vulkan
sudo apt install -y vulkan-tools mesa-vulkan-drivers

# Verificar dispositivos Vulkan
vulkaninfo --summary | grep "deviceName"
```

### 5. Ejecutar Ollama con Docker

```bash
docker-compose up -d
```

## Rendimiento Esperado

| Modelo | Prompt | Generación |
|--------|--------|------------|
| qwen3:8b | ~46 tok/s | ~18 tok/s |
| qwen2.5-coder:14b | ~43 tok/s | ~11.5 tok/s |

## Solución de Problemas

### Error: "containerd.io : Entra en conflicto: containerd"

Ubuntu Server incluye `containerd` por defecto, lo cual causa conflicto con Docker. Soluciones:

**Opción 1: Usar el script actualizado (recomendado)**
```bash
sudo bash install-ubuntu.sh
```

**Opción 2: Resolver manualmente**
```bash
# Eliminar containerd nativo
sudo apt remove containerd

# Agregar repositorio oficial de Docker
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Agregar repositorio
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

**Opción 3: Omitir instalación de Docker**
```bash
sudo bash install-ubuntu-no-docker.sh
```

### El driver radeon sigue cargándose

Verifica que los parámetros del kernel estén presentes:

```bash
cat /proc/cmdline | grep amdgpu
```

Deberías ver `radeon.si_support=0 amdgpu.si_support=1`

### Vulkan no detecta las GPUs

Instala los drivers Mesa:

```bash
sudo apt install -y mesa-vulkan-drivers
```

### Ollama no usa la GPU

Asegúrate de establecer la variable de entorno:

```bash
export OLLAMA_VULKAN=1
docker-compose up -d
```

## Archivos

- `setup-gpu-ubuntu.sh` - Script principal de configuración
- `tui-ubuntu.sh` - Interfaz interactiva
- `docker-compose.yml` - Configuración de Docker
