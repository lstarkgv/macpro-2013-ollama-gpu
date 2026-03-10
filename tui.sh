#!/bin/bash

# TUI for Mac Pro 2013 GPU Setup

TITLE="Mac Pro 2013 GPU Setup"

if ! command -v whiptail &> /dev/null; then
    echo "whiptail not found. Please install it or use setup-gpu.sh."
    exit 1
fi

whiptail --title "$TITLE" --msgbox "Welcome to the Mac Pro 2013 GPU Setup Utility. This will help you enable GPU acceleration for Ollama on dual FirePro D700s." 10 60

CHOICE=$(whiptail --title "$TITLE" --menu "Choose an action:" 15 60 4 
"1" "Enable GPU Driver (amdgpu)" 
"2" "Check Driver Status" 
"3" "View Ollama Config" 
"4" "Exit" 3>&1 1>&2 2>&3)

case $CHOICE in
    1)
        if whiptail --title "$TITLE" --yesno "This will modify /etc/default/grub and regenerate your boot config. Are you sure?" 10 60; then
            bash ./setup-gpu.sh
            whiptail --title "$TITLE" --msgbox "Changes applied! Please reboot your system." 10 60
        fi
        ;;
    2)
        STATUS=$(lspci -k | grep -A 3 -E "(VGA|3D)")
        whiptail --title "$TITLE" --msgbox "Driver Status:

$STATUS" 15 70
        ;;
    3)
        CONFIG=$(cat ./ollama.container)
        whiptail --title "$TITLE" --scrolltext --msgbox "Podman Quadlet Config:

$CONFIG" 20 70
        ;;
    4)
        exit 0
        ;;
esac
