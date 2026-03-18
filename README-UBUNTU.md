# Mac Pro 2013 Ollama GPU - Ubuntu Server

Configuración para habilitar aceleración GPU en Ollama para Mac Pro 2013 con AMD FirePro D700 en Ubuntu Server.

## Requisitos Previos

- Mac Pro 2013 (6,1) con dual FirePro D700
- Ubuntu Server 22.04 o 24.04
- Acceso sudo

## Instalación

### 1. Instalar dependencias

```bash
sudo apt update
sudo apt install -y whiptail git docker.io docker-compose
```

### 2. Habilitar el driver amdgpu

```bash
# Dar permisos de ejecución
chmod +x setup-gpu-ubuntu.sh

# Ejecutar el script
sudo bash setup-gpu-ubuntu.sh
```

O usa la interfaz TUI:

```bash
chmod +x tui-ubuntu.sh
./tui-ubuntu.sh
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
