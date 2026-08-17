#!/bin/bash
printf "\033c" > /dev/tty1
echo "Switching active frontend to SimpleMenu..."
sudo systemctl disable emulationstation.service 2>/dev/null || true
sudo systemctl stop emulationstation.service 2>/dev/null || true
sudo systemctl enable simplemenu.service 2>/dev/null || true
sudo systemctl start simplemenu.service 2>/dev/null || true
