#!/usr/bin/env bash
# ================================================================================
#  R36XX ON-DEVICE DISPLAY PANEL & DTB SELECTOR
# ================================================================================

set -euo pipefail

BOOT_DIR="/boot"
BACKUP_DIR="/boot/dtb_backups"

echo "=================================================="
echo "    R36XX DISPLAY PANEL & DTB SELECTOR"
echo "=================================================="

if [ "$EUID" -ne 0 ]; then
    echo "Error: This utility requires root privileges."
    echo "Please launch via sudo."
    exit 1
fi

mkdir -p "$BACKUP_DIR"

echo "Current Active DTBs in $BOOT_DIR:"
ls -lh "$BOOT_DIR"/*.dtb 2>/dev/null || echo "No DTBs currently in /boot."
echo ""
echo "Options:"
echo "  [1] Backup current active DTBs"
echo "  [2] Restore original factory DTB backup"
echo "  [3] Re-apply Panel 4 IPS Native Timing (640x480)"
echo "  [4] Exit"
echo ""

read -rp "Select option [1-4]: " CHOICE

case "$CHOICE" in
    1)
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        mkdir -p "$BACKUP_DIR/$TIMESTAMP"
        cp -vf "$BOOT_DIR"/*.dtb "$BACKUP_DIR/$TIMESTAMP/" 2>/dev/null || true
        echo "Backup created at: $BACKUP_DIR/$TIMESTAMP"
        ;;
    2)
        LATEST_BAK=$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | sort -r | head -n 1)
        if [ -n "$LATEST_BAK" ] && [ -d "$LATEST_BAK" ]; then
            echo "Restoring from $LATEST_BAK..."
            cp -vf "$LATEST_BAK"/*.dtb "$BOOT_DIR/"
            sync
            echo "Restoration complete! Reboot to apply."
        else
            echo "No backups found in $BACKUP_DIR."
        fi
        ;;
    3)
        echo "Re-applying Panel 4 IPS timing..."
        if [ -f "/usr/local/share/r36xx/rk3326-rg351mp-linux.dtb" ]; then
            cp -vf /usr/local/share/r36xx/*.dtb "$BOOT_DIR/"
            sync
            echo "Panel 4 applied successfully! Reboot to apply."
        else
            echo "Panel 4 master files not found in system cache."
        fi
        ;;
    4|*)
        echo "Exiting..."
        exit 0
        ;;
esac

echo "Done!"
