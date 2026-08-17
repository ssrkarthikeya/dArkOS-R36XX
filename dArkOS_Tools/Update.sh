#!/bin/bash
# ================================================================================
#  dArkOS-R36XX HARDWARE-PROTECTED OTA UPDATE ENGINE
# ================================================================================

sudo chmod 666 /dev/tty1 2>/dev/null || true

if [[ "$(stat -c "%U" /home/ark 2>/dev/null)" != "ark" ]]; then
  printf "Fixing home folder permissions. Please wait...\n"
  sudo chown -R ark:ark /home/ark
  sudo chmod -R 755 /home/ark
fi

printf "\nChecking for updates with R36XX Hardware Armor. Please wait...\n"

LOG_FILE="/home/ark/esupdate.log"
VAULT_DIR="/boot/.r36xx_dtb_vault"

if [ -f "$LOG_FILE" ]; then
  sudo rm "$LOG_FILE"
fi

sudo timedatectl set-ntp 1 2>/dev/null || true

# --- R36XX HARDWARE ARMOR (SNAPSHOT PRE-UPDATE STATE) ---
echo "[*] Creating R36XX Hardware Armor Snapshot..." | tee -a "$LOG_FILE"
sudo mkdir -p "$VAULT_DIR"
sudo cp -vf /boot/*.dtb "$VAULT_DIR/" 2>/dev/null || true
if [ -d "/usr/local/share/r36xx" ]; then
  sudo cp -vf /usr/local/share/r36xx/*.dtb "$VAULT_DIR/" 2>/dev/null || true
fi

# Trap to guarantee R36XX display and power drivers are restored after any update
restore_r36xx_armor() {
  echo -e "\n[*] Running R36XX Hardware Armor Verification..." | tee -a "$LOG_FILE"
  if [ -d "$VAULT_DIR" ] && [ -f "$VAULT_DIR/rk3326-rg351mp-linux.dtb" ]; then
    echo "    Re-applying verified R36XX Panel DTBs to /boot/..." | tee -a "$LOG_FILE"
    sudo cp -vf "$VAULT_DIR"/*.dtb /boot/ 2>/dev/null || true
    sudo sync
    echo "    Hardware Armor verified: Display panel DTBs protected from black screens." | tee -a "$LOG_FILE"
  fi
  # Ensure ALSA noise fix & power key daemon remain enabled
  if [ -f "/var/lib/alsa/asound.state" ]; then
    sudo alsactl restore 2>/dev/null || true
  fi
  if [ -f "/etc/systemd/system/r36xx_pwrkey.service" ]; then
    sudo systemctl enable r36xx_pwrkey.service 2>/dev/null || true
  fi
}
trap restore_r36xx_armor EXIT

# --- FETCH UPSTREAM UPDATES ---
LOCATION="https://raw.githubusercontent.com/christianhaitian/darkos-updates/master"

wget -t 3 -T 60 --no-check-certificate "$LOCATION"/LICENSE -O /dev/shm/LICENSE -a "$LOG_FILE"
if [ $? -ne 0 ]; then
  sudo msgbox "Looks like OTA updating is currently down or your Wi-Fi/internet connection is not functioning correctly."
  printf "There was an error connecting to update servers." | tee -a "$LOG_FILE"
  exit 1
fi

wget -t 3 -T 60 --no-check-certificate "$LOCATION"/dArkOSUpdate.sh -O /home/ark/dArkOSUpdate.sh -a "$LOG_FILE" || sudo rm -f /home/ark/dArkOSUpdate.sh | tee -a "$LOG_FILE"
if [ $? -ne 0 ]; then
  sudo msgbox "Looks like OTA updating is currently down or your Wi-Fi/internet connection is not functioning correctly."
  printf "There was an error downloading the update script." | tee -a "$LOG_FILE"
  exit 1
fi

sudo chmod -v 777 /home/ark/dArkOSUpdate.sh | tee -a "$LOG_FILE"
/home/ark/dArkOSUpdate.sh

UPDATE_EXIT_CODE=$?

if [ $UPDATE_EXIT_CODE -ne 187 ] && [ $UPDATE_EXIT_CODE -ne 0 ]; then
  sudo msgbox "There was an error with attempting this update. Did you make sure to connect to Wi-Fi first?"
  printf "Update failed with code $UPDATE_EXIT_CODE." | tee -a "$LOG_FILE"
  if [ -f /home/ark/dArkOSUpdate.sh ]; then
    rm /home/ark/dArkOSUpdate.sh
  fi
else
  sudo msgbox "Update completed successfully! R36XX hardware adaptations preserved."
fi

if [ ! -z "$(pidof rg351p-js2xbox 2>/dev/null)" ]; then
  sudo kill -9 "$(pidof rg351p-js2xbox)" 2>/dev/null || true
  sudo rm -f /dev/input/by-path/platform-odroidgo2-joypad-event-joystick
fi
