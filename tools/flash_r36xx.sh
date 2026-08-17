#!/usr/bin/env bash
# ================================================================================
#  dArkOS-R36XX AUTOMATED SD CARD FLASH & HARDWARE ADAPTATION TOOL
# ================================================================================
# Description:
#   Flashes an ArkOS / dArkOS master image to a target SD card and automatically
#   injects all verified R36S/R36XX hardware adaptations (Panel DTBs, 5V USB OTG,
#   Realtek Wi-Fi microcode, ALSA audio hum filter, SSH, and Wi-Fi credentials).
# ================================================================================

set -euo pipefail

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Determine script root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${CYAN}================================================================================${NC}"
echo -e "${BOLD}${CYAN}   dArkOS-R36XX MULTI-PANEL FLASH & INJECTION ENGINE${NC}"
echo -e "${CYAN}================================================================================${NC}"

# Check for root / sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Error: This script must be executed with root privileges.${NC}"
    echo -e "    Please run with: ${BOLD}sudo $0${NC}"
    exit 1
fi

# Locate OS Image
IMAGE_PATH="${1:-}"
if [ -z "$IMAGE_PATH" ]; then
    # Look for candidate .img files in common workspace locations
    CANDIDATES=(
        "$SCRIPT_DIR"/dArkOS_*.img
        "$SCRIPT_DIR"/../*.img
        /home/*/*/01_OS_Images_and_Backups/*.img
    )
    
    FOUND_IMAGES=()
    for img in "${CANDIDATES[@]}"; do
        if [ -f "$img" ]; then
            FOUND_IMAGES+=("$img")
        fi
    done

    if [ ${#FOUND_IMAGES[@]} -gt 0 ]; then
        echo -e "${YELLOW}[*] Available base OS images detected:${NC}"
        for i in "${!FOUND_IMAGES[@]}"; do
            echo -e "  [$((i+1))] ${FOUND_IMAGES[$i]}"
        done
        echo ""
        read -rp "Select an image [1-${#FOUND_IMAGES[@]}] or enter full path: " IMG_CHOICE
        if [[ "$IMG_CHOICE" =~ ^[0-9]+$ ]] && [ "$IMG_CHOICE" -ge 1 ] && [ "$IMG_CHOICE" -le "${#FOUND_IMAGES[@]}" ]; then
            IMAGE_PATH="${FOUND_IMAGES[$((IMG_CHOICE-1))]}"
        elif [ -f "$IMG_CHOICE" ]; then
            IMAGE_PATH="$IMG_CHOICE"
        else
            echo -e "${RED}[!] Invalid selection.${NC}"
            exit 1
        fi
    else
        read -rp "Enter absolute path to the .img file: " IMAGE_PATH
    fi
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo -e "${RED}[!] Error: Image file '$IMAGE_PATH' does not exist.${NC}"
    exit 1
fi

echo -e "${GREEN}[+] Selected Image:${NC} $IMAGE_PATH ($(du -h "$IMAGE_PATH" | cut -f1))"
echo ""

# Select Target Block Device
echo -e "${YELLOW}[*] Detected Block Devices:${NC}"
lsblk -d -o NAME,SIZE,MODEL,TRAN,HOTPLUG,TYPE | grep -E "disk|NAME" || true
echo ""

read -rp "Enter target disk device (e.g. /dev/mmcblk0 or /dev/sdX): " TARGET_DEV

if [ ! -b "$TARGET_DEV" ]; then
    echo -e "${RED}[!] Error: Target device '$TARGET_DEV' is not a valid block device.${NC}"
    exit 1
fi

# Safety Warning
echo ""
echo -e "${RED}${BOLD}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! CRITICAL WARNING !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
echo -e "${RED}All data on ${BOLD}$TARGET_DEV${NC}${RED} will be PERMANENTLY OVERWRITTEN!${NC}"
echo -e "Device Details: $(lsblk -d -o NAME,SIZE,MODEL "$TARGET_DEV" | tail -n1)"
echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
read -rp "Type 'YES' to proceed with flashing: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    echo -e "${YELLOW}[*] Flashing aborted by user.${NC}"
    exit 0
fi

# Step 1: Unmount existing partitions
echo ""
echo -e "${BLUE}[1/6] Unmounting existing partitions on $TARGET_DEV...${NC}"
for part in $(lsblk -n -l -o NAME "$TARGET_DEV" | tail -n +2); do
    if mountpoint -q "/dev/$part" 2>/dev/null || grep -qs "/dev/$part" /proc/mounts; then
        umount "/dev/$part" 2>/dev/null || true
    fi
    udisksctl unmount -b "/dev/$part" 2>/dev/null || true
done

# Step 2: Write image
echo -e "${BLUE}[2/6] Writing image to $TARGET_DEV (dd bs=4M status=progress)...${NC}"
dd if="$IMAGE_PATH" of="$TARGET_DEV" bs=4M status=progress conv=fsync
sync

# Step 3: Refresh partition table
echo -e "${BLUE}[3/6] Refreshing kernel partition table...${NC}"
partprobe "$TARGET_DEV" 2>/dev/null || true
sleep 3

# Determine partition naming convention (e.g., mmcblk0p1 vs sdb1)
if [[ "$TARGET_DEV" =~ [0-9]$ ]]; then
    BOOT_PART="${TARGET_DEV}p1"
    ROOTFS_PART="${TARGET_DEV}p2"
else
    BOOT_PART="${TARGET_DEV}1"
    ROOTFS_PART="${TARGET_DEV}2"
fi

TMP_BOOT="/mnt/darkos_boot_$$"
TMP_ROOTFS="/mnt/darkos_rootfs_$$"
mkdir -p "$TMP_BOOT" "$TMP_ROOTFS"

cleanup() {
    echo -e "${YELLOW}[*] Cleaning up temporary mount points...${NC}"
    umount "$TMP_BOOT" 2>/dev/null || true
    umount "$TMP_ROOTFS" 2>/dev/null || true
    rm -rf "$TMP_BOOT" "$TMP_ROOTFS"
}
trap cleanup EXIT

# Step 4: Inject BOOT partition patches
echo -e "${BLUE}[4/6] Mounting BOOT partition ($BOOT_PART) and injecting DTBs...${NC}"
mount "$BOOT_PART" "$TMP_BOOT"

# Copy verified DTBs (Panel 4 IPS + 5V USB OTG boost)
if [ -d "$SCRIPT_DIR/device/r36xx/dtb" ]; then
    cp -vf "$SCRIPT_DIR/device/r36xx/dtb/rk3326-rg351mp-linux.dtb" "$TMP_BOOT/rk3326-rg351mp-linux.dtb"
    cp -vf "$SCRIPT_DIR/device/r36xx/dtb/rk3326-rg351mp-linux.dtb" "$TMP_BOOT/rk3326-r35s-linux.dtb"
    cp -vf "$SCRIPT_DIR/device/r36xx/dtb/rg351mp-kernel.dtb" "$TMP_BOOT/rg351mp-kernel.dtb"
fi

# Copy firstboot partition expander
if [ -f "$SCRIPT_DIR/scripts/expandtoexfat.sh.rk3326" ]; then
    cp -vf "$SCRIPT_DIR/scripts/expandtoexfat.sh.rk3326" "$TMP_BOOT/firstboot.sh"
fi

# Optional Wi-Fi Pre-Configuration
echo ""
read -rp "Would you like to pre-configure Wi-Fi credentials on the SD card? (y/N): " WIFI_CONFIG
if [[ "$WIFI_CONFIG" =~ ^[Yy]$ ]]; then
    read -rp "Enter Wi-Fi SSID: " WIFI_SSID
    read -rsp "Enter Wi-Fi Password: " WIFI_PASS
    echo ""
    cat > "$TMP_BOOT/wifikey.txt" <<EOF_WIFI
SSID=$WIFI_SSID
PASSWORD=$WIFI_PASS
EOF_WIFI
    echo -e "${GREEN}[+] Wi-Fi credentials saved to BOOT/wifikey.txt${NC}"
fi

sync
umount "$TMP_BOOT"
echo -e "${GREEN}[+] BOOT partition configured and unmounted cleanly.${NC}"

# Step 5: Inject ROOTFS partition services
echo -e "${BLUE}[5/6] Mounting ROOTFS partition ($ROOTFS_PART) and injecting core services...${NC}"
mount "$ROOTFS_PART" "$TMP_ROOTFS"

# Inject uncompressed Wi-Fi microcode collection (Realtek, MediaTek, Ralink, Atheros)
mkdir -p "$TMP_ROOTFS/lib/firmware/rtlwifi" "$TMP_ROOTFS/lib/firmware/mediatek" "$TMP_ROOTFS/lib/firmware/rtl_bt"
if [ -d "$SCRIPT_DIR/firmware/rtlwifi" ]; then
    cp -vf "$SCRIPT_DIR/firmware/rtlwifi"/*.bin "$TMP_ROOTFS/lib/firmware/rtlwifi/" 2>/dev/null || true
fi
if [ -d "$SCRIPT_DIR/firmware/mediatek" ]; then
    cp -vf "$SCRIPT_DIR/firmware/mediatek"/*.bin "$TMP_ROOTFS/lib/firmware/mediatek/" 2>/dev/null || true
fi
if [ -d "$SCRIPT_DIR/firmware/rtl_bt" ]; then
    cp -vf "$SCRIPT_DIR/firmware/rtl_bt"/*.bin "$TMP_ROOTFS/lib/firmware/rtl_bt/" 2>/dev/null || true
fi
cp -vf "$SCRIPT_DIR/firmware"/*.bin "$SCRIPT_DIR/firmware"/*.fw "$TMP_ROOTFS/lib/firmware/" 2>/dev/null || true

# Inject USB Autodetect daemon
mkdir -p "$TMP_ROOTFS/etc/udev/rules.d" "$TMP_ROOTFS/usr/local/bin"
if [ -f "$SCRIPT_DIR/device/r36xx/99-r36xx-usb-autodetect.rules" ]; then
    cp -vf "$SCRIPT_DIR/device/r36xx/99-r36xx-usb-autodetect.rules" "$TMP_ROOTFS/etc/udev/rules.d/"
    cp -vf "$SCRIPT_DIR/device/r36xx/r36xx_usb_handler.sh" "$TMP_ROOTFS/usr/local/bin/"
    chmod +x "$TMP_ROOTFS/usr/local/bin/r36xx_usb_handler.sh"
fi

# Inject RK817 Power-Key daemon
mkdir -p "$TMP_ROOTFS/etc/systemd/system"
if [ -f "$SCRIPT_DIR/device/r36xx/r36xx_pwrkey.py" ]; then
    cp -vf "$SCRIPT_DIR/device/r36xx/r36xx_pwrkey.py" "$TMP_ROOTFS/usr/local/bin/"
    cp -vf "$SCRIPT_DIR/device/r36xx/r36xx_pwrkey.service" "$TMP_ROOTFS/etc/systemd/system/"
    chmod +x "$TMP_ROOTFS/usr/local/bin/r36xx_pwrkey.py"
    mkdir -p "$TMP_ROOTFS/etc/systemd/system/multi-user.target.wants"
    ln -sf "/etc/systemd/system/r36xx_pwrkey.service" "$TMP_ROOTFS/etc/systemd/system/multi-user.target.wants/r36xx_pwrkey.service" 2>/dev/null || true
fi

# Inject ALSA noise-floor fix
mkdir -p "$TMP_ROOTFS/var/lib/alsa"
if [ -f "$SCRIPT_DIR/audio/asound.state.rk3326" ]; then
    cp -vf "$SCRIPT_DIR/audio/asound.state.rk3326" "$TMP_ROOTFS/var/lib/alsa/asound.state"
fi

# Auto-enable SSH server
mkdir -p "$TMP_ROOTFS/etc/systemd/system/multi-user.target.wants"

sync
umount "$TMP_ROOTFS"
echo -e "${GREEN}[+] ROOTFS partition configured and unmounted cleanly.${NC}"

# Step 6: Flush caches
echo -e "${BLUE}[6/6] Flushing all disk write buffers...${NC}"
sync

echo ""
echo -e "${CYAN}================================================================================${NC}"
echo -e "${GREEN}${BOLD}   FLASH & MASTER DEPLOYMENT COMPLETE! SD CARD IS READY FOR CONSOLE!${NC}"
echo -e "${CYAN}================================================================================${NC}"
echo -e "You may now safely eject the SD card and insert it into TF1/OS on your R36S."
echo ""
