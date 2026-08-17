#!/bin/bash
# ==============================================================================
# dArkOS-R36XX Auto Wi-Fi Importer
# Reads /boot/wifikey.txt or /roms/wifikey.txt and connects automatically
# Format of wifikey.txt:
# SSID="MyNetworkName"
# PASSWORD="MyPassword123"
# ==============================================================================

LOG="/boot/wifi_importer.log"
CONFIG_BOOT="/boot/wifikey.txt"
CONFIG_ROMS="/roms/wifikey.txt"

log() {
  echo "[$(date +"%Y-%m-%d %H:%M:%S")] $1" >> "$LOG"
}

CONFIG=""
if [ -f "$CONFIG_BOOT" ]; then
  CONFIG="$CONFIG_BOOT"
elif [ -f "$CONFIG_ROMS" ]; then
  CONFIG="$CONFIG_ROMS"
fi

if [ -z "$CONFIG" ]; then
  exit 0
fi

log "Found Wi-Fi config file: $CONFIG"

# Source the configuration
SSID=""
PASSWORD=""
source "$CONFIG"

if [ -z "$SSID" ]; then
  log "Error: SSID is empty in $CONFIG"
  exit 1
fi

log "Attempting to connect to SSID: $SSID..."

# Ensure NetworkManager is running
sudo systemctl start NetworkManager 2>/dev/null || true
sleep 2

# Connect using nmcli
if [ -n "$PASSWORD" ]; then
  OUTPUT=$(sudo nmcli dev wifi connect "$SSID" password "$PASSWORD" 2>&1)
else
  OUTPUT=$(sudo nmcli dev wifi connect "$SSID" 2>&1)
fi

EXIT_CODE=$?
log "nmcli output: $OUTPUT (exit code $EXIT_CODE)"

if [ $EXIT_CODE -eq 0 ]; then
  IP=$(ip -4 addr show wlan0 2>/dev/null | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n 1)
  log "SUCCESS! Connected to $SSID with IP: $IP"
  echo "Connected to $SSID (IP: $IP) at $(date)" > /boot/wifi_connected.txt
  
  # Remove plaintext password file for security
  rm -f "$CONFIG"
  log "Removed config file $CONFIG"
else
  log "FAILED to connect to $SSID"
  echo "Failed to connect to $SSID: $OUTPUT" > /boot/wifi_error.txt
fi
