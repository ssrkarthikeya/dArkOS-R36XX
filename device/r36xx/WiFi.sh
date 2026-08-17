#!/bin/bash
# ==============================================================================
# dArkOS-R36XX Interactive Wi-Fi & Network Manager
# ==============================================================================

sudo chmod 666 /dev/tty1
export TERM=linux
height="18"
width="60"

# Check for font
if [ -f "/boot/rk3326-rg351mp-linux.dtb" ]; then
  sudo setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz 2>/dev/null || true
fi

sudo systemctl start NetworkManager 2>/dev/null || true

while true; do
  # Get current IP and status
  IP_WLAN=$(ip -4 addr show wlan0 2>/dev/null | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n 1)
  IP_ETH=$(ip -4 addr show usb0 2>/dev/null | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n 1)
  CURRENT_SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep "^yes" | cut -d: -f2)

  STATUS_MSG="Status: Not connected"
  if [ -n "$CURRENT_SSID" ]; then
    STATUS_MSG="Connected to: $CURRENT_SSID | IP: $IP_WLAN"
  elif [ -n "$IP_ETH" ]; then
    STATUS_MSG="Connected via USB Tethering | IP: $IP_ETH"
  fi

  CHOICE=$(dialog --clear --title "dArkOS Wi-Fi Manager"     --menu "$STATUS_MSG

Select an option:" $height $width 6     1 "Scan & Connect to Wi-Fi"     2 "NetworkManager Setup (nmtui)"     3 "Check USB Wi-Fi / Dongle Info"     4 "Enable USB Phone Tethering (usb0)"     5 "Disconnect All Wi-Fi"     6 "Exit to Menu"     2>&1 > /dev/tty1)

  case "$CHOICE" in
    1)
      dialog --infobox "Scanning for Wi-Fi networks (please wait)..." 8 50 > /dev/tty1
      sudo nmcli dev wifi rescan 2>/dev/null || true
      sleep 2
      
      # Build list of SSIDs
      SSID_LIST=()
      while IFS= read -r line; do
        if [ -n "$line" ]; then
          SSID_LIST+=("$line" "")
        fi
      done < <(nmcli -t -f ssid dev wifi | grep -v "^$" | sort -u | head -n 15)

      if [ ${#SSID_LIST[@]} -eq 0 ]; then
        dialog --msgbox "No Wi-Fi networks found.
Please ensure your USB Wi-Fi dongle is connected to the OTG port." 8 50 > /dev/tty1
        continue
      fi

      SELECTED_SSID=$(dialog --title "Select Wi-Fi Network" --menu "Choose an SSID:" 18 55 10 "${SSID_LIST[@]}" 2>&1 > /dev/tty1)
      if [ -n "$SELECTED_SSID" ]; then
        PASS=$(dialog --title "Password for $SELECTED_SSID" --inputbox "Enter Wi-Fi Password (leave empty if open network):" 10 50 2>&1 > /dev/tty1)
        dialog --infobox "Connecting to $SELECTED_SSID..." 8 50 > /dev/tty1
        if [ -n "$PASS" ]; then
          OUT=$(sudo nmcli dev wifi connect "$SELECTED_SSID" password "$PASS" 2>&1)
        else
          OUT=$(sudo nmcli dev wifi connect "$SELECTED_SSID" 2>&1)
        fi
        dialog --msgbox "$OUT" 10 55 > /dev/tty1
      fi
      ;;
    2)
      nmtui > /dev/tty1 2>&1
      ;;
    3)
      INFO=$(echo -e "=== USB Devices (lsusb) ===
$(lsusb 2>&1)

=== Network Interfaces ===
$(ip -br link 2>&1)")
      dialog --title "Hardware & Interface Info" --msgbox "$INFO" 18 58 > /dev/tty1
      ;;
    4)
      dialog --infobox "Configuring USB Phone Tethering (usb0)..." 8 50 > /dev/tty1
      sudo modprobe rndis_host cdc_ether 2>/dev/null || true
      sudo dhclient usb0 2>&1
      sleep 2
      IP_USB=$(ip -4 addr show usb0 2>/dev/null | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n 1)
      dialog --msgbox "USB Tethering Status:
IP: ${IP_USB:-No connection found}" 10 50 > /dev/tty1
      ;;
    5)
      sudo nmcli dev disconnect wlan0 2>/dev/null || true
      dialog --msgbox "Disconnected from Wi-Fi." 8 40 > /dev/tty1
      ;;
    6|"")
      break
      ;;
  esac
done
clear > /dev/tty1
