#!/bin/bash
# ================================================================================
#  dArkOS-R36XX REMOTE SERVICES MANAGER
# ================================================================================

sudo chmod 666 /dev/tty1 2>/dev/null || true
reset > /dev/tty1 2>&1 || true
printf "\e[?25l" > /dev/tty1

height="18"
width="60"

# Fetch active IP Address
get_ip() {
    ip route show default 0.0.0.0/0 2>/dev/null | awk '{print $5}' | head -n1 | xargs -I{} ip -4 addr show dev {} 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 || echo "Not Connected"
}

while true; do
    IP=$(get_ip)
    [ -z "$IP" ] && IP="Not Connected"

    # Check Service Statuses
    if systemctl is-active --quiet ssh 2>/dev/null; then
        SSH_STATUS="\Z2[RUNNING]\Zn"
    else
        SSH_STATUS="\Z1[STOPPED]\Zn"
    fi

    if systemctl is-active --quiet smbd 2>/dev/null; then
        SAMBA_STATUS="\Z2[RUNNING]\Zn"
    else
        SAMBA_STATUS="\Z1[STOPPED]\Zn"
    fi

    if pgrep -f "filebrowser" >/dev/null 2>&1; then
        FB_STATUS="\Z2[RUNNING]\Zn"
    else
        FB_STATUS="\Z1[STOPPED]\Zn"
    fi

    if [ "$(timedatectl show -p NTP --value 2>/dev/null)" = "yes" ]; then
        NTP_STATUS="\Z2[ACTIVE]\Zn"
    else
        NTP_STATUS="\Z1[OFF]\Zn"
    fi

    CHOICE=$(dialog --colors --clear \
        --backtitle "dArkOS-R36XX Services Management | IP: $IP" \
        --title " Remote Services Manager " \
        --menu "\nToggle services individually below:\n " \
        $height $width 6 \
        "1" "SSH Server (Port 22)        $SSH_STATUS" \
        "2" "Samba File Share (/roms)   $SAMBA_STATUS" \
        "3" "Web File Browser (Port 80) $FB_STATUS" \
        "4" "NTP Time Synchronization   $NTP_STATUS" \
        "5" "Disable All Services" \
        "6" "Exit" \
        3>&1 1>&2 2>&3)

    case "$CHOICE" in
        1)
            if systemctl is-active --quiet ssh; then
                sudo systemctl stop ssh.service
                dialog --msgbox "SSH Server has been STOPPED." 6 45
            else
                sudo systemctl start ssh.service
                dialog --msgbox "SSH Server STARTED.\n\nConnect via: ssh ark@$IP\nPassword: ark" 8 50
            fi
            ;;
        2)
            if systemctl is-active --quiet smbd; then
                sudo systemctl stop smbd.service nmbd.service
                dialog --msgbox "Samba File Sharing has been STOPPED." 6 45
            else
                sudo systemctl start smbd.service nmbd.service
                dialog --msgbox "Samba File Sharing STARTED.\n\nAccess in Explorer: \\\\$IP\\roms" 8 50
            fi
            ;;
        3)
            if pgrep -f "filebrowser" >/dev/null 2>&1; then
                sudo pkill -f filebrowser
                dialog --msgbox "Web File Browser has been STOPPED." 6 45
            else
                sudo filebrowser -a 0.0.0.0 -p 80 -d /home/ark/.config/filebrowser.db -r / &
                dialog --msgbox "Web File Browser STARTED.\n\nAccess in Browser: http://$IP:80" 8 50
            fi
            ;;
        4)
            if [ "$(timedatectl show -p NTP --value 2>/dev/null)" = "yes" ]; then
                sudo timedatectl set-ntp 0
                dialog --msgbox "NTP Time Sync has been DISABLED." 6 45
            else
                sudo timedatectl set-ntp 1
                dialog --msgbox "NTP Time Sync has been ENABLED." 6 45
            fi
            ;;
        5)
            sudo systemctl stop ssh.service smbd.service nmbd.service 2>/dev/null || true
            sudo pkill -f filebrowser 2>/dev/null || true
            sudo timedatectl set-ntp 0 2>/dev/null || true
            dialog --msgbox "All remote services have been stopped." 6 45
            ;;
        6|*)
            break
            ;;
    esac
done

printf "\e[?25h" > /dev/tty1
clear > /dev/tty1 2>&1 || true
