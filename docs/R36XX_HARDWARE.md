# 🎮 R36S / R36XX Hardware Specification & Adaptation Matrix

## 1. System Overview
The **R36S / R36XX** is a low-cost, high-performance retro gaming handheld powered by the **Rockchip RK3326** SoC. This document provides technical specifications and implementation details for running **dArkOS (Debian 13 Trixie)** on this platform.

| Subsystem | Specification | Driver / Kernel Implementation |
|---|---|---|
| **SoC** | Rockchip RK3326 (4x ARM Cortex-A35 @ 1.5 GHz) | Linux Kernel 4.4.189+ arm64 |
| **GPU** | ARM Mali-G31 MP2 | Mesa 24.x Panfrost / DRM-KMS |
| **RAM** | 1 GB DDR3L / DDR4 | 64-bit / 32-bit Multiarch Userspace |
| **Display** | 3.5" IPS LCD (640x480, 4:3 Aspect Ratio) | Panel 1 through Panel 8 Timing Trees |
| **Audio** | Realtek ALC5672 / RK817 Internal Codec | ALSA (`Playback Path: SPK`, Mic Muted) |
| **PMIC** | Rockchip RK817-1 | ADC Battery Curve + Graceful Key Daemon |
| **USB** | 2x USB Type-C (1x DC In, 1x OTG Host) | 5V OTG Step-Up Boost Enabled |
| **Storage** | Dual MicroSD (TF1/OS + TF2/ROMS) | ext4 / BTRFS (Root) + exFAT / FAT32 (Games) |
| **Network** | External USB OTG Wi-Fi Dongle | Realtek RTL8188EUS, RTL8192EU, RTL8821CU |

---

## 2. Display Panels & Timing Configurations
The R36S market utilizes several interchangeable display panels from different suppliers (commonly designated Panel 1 through Panel 8).

### Panel Timing Overview:
- **Panel 4 (Verified Default)**: Uses native `640x480` timing with optimized vertical refresh and backlight PWM frequency.
- **DTBs Required**:
  - `rk3326-rg351mp-linux.dtb`
  - `rk3326-r35s-linux.dtb`
  - `rg351mp-kernel.dtb`

### On-Device Panel Switching:
Users can switch panel configurations directly from the handheld:
- Navigate to **Options** -> **Tools** -> **Switch Display Panel** (or run `/opt/system/Switch_Panel.sh` via terminal).

---

## 3. Power Management & RK817 Battery Profiling
- **Voltage Calibration**:
  - `4.18V` -> 100%
  - `3.80V` -> ~50%
  - `3.55V` -> 15% (Low Battery Warning LED)
  - `3.40V` -> Critical (Auto-shutdown initiated)
- **Power Button**: Handled gracefully via the `r36xx_pwrkey.py` daemon listening directly to input events (`/dev/input/event*`), executing clean system shutdown rather than hard resets.

---

## 4. USB OTG & Networking Subsystem
- **5V VBUS Power**: Enabled in the Device Tree to ensure sufficient current for USB Wi-Fi dongles (e.g. TP-Link TL-WN725N) and external USB Flash drives.
- **Auto-Detect Daemon**: `/usr/local/bin/r36xx_usb_handler.sh` listens via udev for newly plugged network adapters and initiates automatic DHCP connection using network parameters in `/boot/wifikey.txt`.

---

## 5. Audio Noise-Floor Calibration
Due to shared ground planes between the Wi-Fi OTG line and the internal speaker amplifier, the mic capture preamp can pick up RF hum. The system enforces:
```ini
# /var/lib/alsa/asound.state
Playback Path = 'SPK'
Capture MIC Path = 'MIC OFF'
```
This reduces idle noise floor to near 0 dB while maintaining full volume output on both speakers and 3.5mm stereo headphones.
