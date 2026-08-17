#!/bin/bash
# ==============================================================================
# dArkOS-R36XX Intelligent USB Hotplug Handler
# ==============================================================================

EVENT="$1"
IFACE="$2"
LOG="/boot/usb_hotplug.log"

log() {
  echo "[$(date "+%Y-%m-%d %H:%M:%S")] [USB-HOTPLUG] $1" >> "$LOG" 2>/dev/null || true
}

case "$EVENT" in
  wifi_add)
    log "Wi-Fi Dongle connected ($IFACE). Starting NetworkManager..."
    rfkill unblock all 2>/dev/null || true
    rfkill unblock wifi 2>/dev/null || true
    systemctl start NetworkManager 2>/dev/null || true
    sleep 2
    if [ -f "/boot/wifikey.txt" ] && [ -x "/usr/local/bin/importwifi.sh" ]; then
      /usr/local/bin/importwifi.sh &
    fi
    (
      sleep 5
      IP=$(ip -4 addr show "$IFACE" 2>/dev/null | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n 1)
      if [ -n "$IP" ]; then
        log "Wi-Fi ($IFACE) Online! IP: $IP"
        echo "Wi-Fi IP: $IP (Connected on $(date))" > /boot/wifi_connected.txt
      fi
    ) &
    ;;

  wifi_remove)
    log "Wi-Fi Dongle removed ($IFACE)."
    rm -f /boot/wifi_connected.txt 2>/dev/null || true
    ;;

  tether_add)
    log "Android Phone Tethering connected ($IFACE). Requesting DHCP..."
    modprobe rndis_host cdc_ether cdc_ncm 2>/dev/null || true
    dhclient -r "$IFACE" 2>/dev/null || true
    dhclient -v "$IFACE" >> "$LOG" 2>&1 &
    (
      sleep 4
      IP=$(ip -4 addr show "$IFACE" 2>/dev/null | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | head -n 1)
      if [ -n "$IP" ]; then
        log "Phone Tethering ($IFACE) Online! IP: $IP"
        echo "Tethering IP: $IP (Connected on $(date))" > /boot/tether_connected.txt
      fi
    ) &
    ;;

  tether_remove)
    log "Phone Tethering disconnected ($IFACE)."
    kill $(pgrep -f "dhclient.*$IFACE") 2>/dev/null || true
    rm -f /boot/tether_connected.txt 2>/dev/null || true
    ;;

  storage_add)
    log "USB Storage Device connected ($IFACE). Auto-mounting to /roms2..."
    mkdir -p /roms2
    mount "/dev/$IFACE" /roms2 2>/dev/null || true
    log "Mounted /dev/$IFACE to /roms2"
    ;;

  storage_remove)
    log "USB Storage Device removed ($IFACE)."
    umount -l /roms2 2>/dev/null || true
    ;;
esac
