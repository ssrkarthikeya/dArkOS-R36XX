#!/bin/bash
printf "\033c" > /dev/tty1
echo "Switching active frontend to EmulationStation..."
sudo systemctl disable simplemenu.service 2>/dev/null || true
sudo systemctl stop simplemenu.service 2>/dev/null || true
sudo systemctl enable emulationstation.service 2>/dev/null || true
sudo systemctl start emulationstation.service 2>/dev/null || true
