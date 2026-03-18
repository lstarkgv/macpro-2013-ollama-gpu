#!/bin/bash

# TUI for Mac Pro 2013 GPU Setup - Ubuntu Server Edition

TITLE="Mac Pro 2013 GPU Setup - Ubuntu"

# Check for whiptail installation
if ! command -v whiptail &> /dev/null; then
    echo "whiptail not found. Installing..."
    sudo apt update && sudo apt install -y whiptail
fi

whiptail --title "$TITLE" --msgbox "Welcome to the Mac Pro 2013 GPU Setup Utility for Ubuntu Server.\n\nThis will help you enable GPU acceleration for Ollama on dual FirePro D700s." 12 60

while true; do
    CHOICE=$(whiptail --title "$TITLE" --menu "Choose an action:" 18 60 5 \
    "1" "Enable GPU Driver (amdgpu)" \
    "2" "Check Driver Status" \
    "3" "Install Vulkan Tools" \
    "4" "View Docker Compose Config" \
    "5" "Exit" 3>&1 1>&2 2>&3)

    case $CHOICE in
        1)
            if whiptail --title "$TITLE" --yesno "This will modify /etc/default/grub and regenerate your boot config.\n\nAre you sure?" 10 60 --yes-button "Yes, Continue" --no-button "Cancel"; then
                sudo bash ./setup-gpu-ubuntu.sh
                whiptail --title "$TITLE" --msgbox "Changes applied!\n\nPlease reboot your system for changes to take effect." 10 60
            fi
            ;;
        2)
            STATUS=$(lspci -k | grep -A 3 -E "(VGA|3D)")
            whiptail --title "$TITLE" --scrolltext --msgbox "Driver Status:\n\n$STATUS" 15 70
            ;;
        3)
            if whiptail --title "$TITLE" --yesno "Install Vulkan tools (vulkan-tools, mesa-vulkan-drivers)?" 10 60; then
                sudo apt update
                sudo apt install -y vulkan-tools mesa-vulkan-drivers
                whiptail --title "$TITLE" --msgbox "Vulkan tools installed successfully!" 10 60
            fi
            ;;
        4)
            if [ -f ./docker-compose.yml ]; then
                CONFIG=$(cat ./docker-compose.yml)
                whiptail --title "$TITLE" --scrolltext --msgbox "Docker Compose Config:\n\n$CONFIG" 20 70
            else
                whiptail --title "$TITLE" --msgbox "docker-compose.yml not found!" 10 60
            fi
            ;;
        5)
            exit 0
            ;;
        *)
            exit 0
            ;;
    esac
done
