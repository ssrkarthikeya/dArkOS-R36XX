# 🎮 dArkOS-R36XX MultiPanel

> **Modern 64-bit Debian 13 (Trixie) Linux Distribution Tailored Specifically for R36S & R36XX Clone Handheld Gaming Consoles (Rockchip RK3326).**

[![GitHub Repository](https://img.shields.io/badge/GitHub-ssrkarthikeya%2FdArkOS--R36XX-blue?style=flat-square&logo=github)](https://github.com/ssrkarthikeya/dArkOS-R36XX)
[![Debian Version](https://img.shields.io/badge/Debian-13%20(Trixie)-red?style=flat-square&logo=debian)](https://www.debian.org/)
[![SoC](https://img.shields.io/badge/SoC-Rockchip%20RK3326-orange?style=flat-square)](https://www.rock-chips.com/)
[![License](https://img.shields.io/badge/License-GPL%20%2F%20MIT-green?style=flat-square)](LICENSES.md)

---

## 🌟 Overview & Key Features

**dArkOS-R36XX** builds upon the foundation of `christianhaitian/dArkOS`, adding native hardware adaptation, power calibration, and screen support for the **R36S / R36XX** family of handhelds:

1. 📱 **Multi-Panel Display Support**:
   - Out-of-the-box compatibility with **Panel 1 through Panel 8** screens.
   - Pre-configured with the verified **Panel 4** display timing tree (`640x480`).
   - Built-in on-device panel switcher utility (`/opt/system/Switch_Panel.sh`).
2. 🛡️ **Hardware-Protected OTA Update Engine**:
   - Built-in DTB Armor Vault in `Update.sh` that automatically snapshots and restores verified R36XX screen panel timings, preventing any upstream kernel updates from causing black screens.
3. 🔒 **Granular Remote Services Manager**:
   - Remote services (SSH, Samba, Web File Browser) are **disabled by default** out of the box for security.
   - Interactive on-device **Remote Services Manager** under Options to independently toggle and configure SSH, Samba Windows Shares, Web File Browser, and NTP.
4. ⚡ **5V USB OTG & Modern Wi-Fi Chipset Support**:
   - 5V USB OTG power boost enabled in DTB for budget USB Wi-Fi dongles and phone tethering.
   - Bundled uncompressed microcode collection for post-2021 budget Wi-Fi dongles:
     - **MediaTek / Ralink**: `MT7601U`, `MT7610U`, `MT7662U`, `RT5370`, `RT2870`, `RT3070`
     - **Realtek**: `RTL8188EUS`, `RTL8188FU`, `RTL8192EU`, `RTL8192FU`, `RTL8821CU`, `RTL8822BU`, `RTL8723BU/DE/BE`
     - **Atheros**: `AR9271`, `AR7010`
   - Plug-and-play Wi-Fi auto-configuration via `/boot/wifikey.txt`.
5. 🔊 **Clean High-Fidelity Audio**:
   - Calibrated ALSA audio state eliminating Wi-Fi RF ground buzz and idle hiss.
6. 🎨 **Curated Clean Themes Pre-Bundled**:
   - Pre-packaged with clean, high-performance 4:3 640x480 EmulationStation themes: `es-theme-epicnoir`, `es-theme-nes-box`, `es-theme-minimal-arkos`, `es-theme-switch`, and `es-theme-art-book-next`.
7. 🔋 **PMIC & Graceful Shutdown**:
   - Tuned ADC battery curve for the onboard **Rockchip RK817-1 PMIC**.
   - Dedicated power-key event daemon for clean, filesystem-safe shutdowns.

---

## 🛠️ Building dArkOS for R36XX

### Recommended Build Environment
* **OS:** Ubuntu 24.04 LTS (Noble) x86_64 or Debian 12/13.
* **Storage:** 50+ GB free space.
* **Privileges:** `sudo` access (required for `debootstrap` and rootfs image generation).

### Quick Build Commands

```bash
# Clone the repository
git clone https://github.com/ssrkarthikeya/dArkOS-R36XX.git
cd dArkOS-R36XX

# Run the dedicated R36XX build engine
./build_r36xx.sh

# Or build via Makefile target
make r36xx
```

---

## ⚡ Automated Flashing Tool (`tools/flash_r36xx.sh`)

We provide an interactive flashing and injection utility to deploy dArkOS / ArkOS directly to your MicroSD card:

```bash
sudo ./tools/flash_r36xx.sh
```

**Features:**
- Automatic block device detection with safety confirmation.
- Direct `dd` write with buffer cache synchronization.
- Automatic injection of Panel DTBs, Wi-Fi drivers, ALSA state, and power daemon.
- Interactive prompt to pre-configure your home Wi-Fi credentials.

---

## 📚 Documentation

For in-depth hardware specifications, schematics, and adaptation matrices, see [`docs/R36XX_HARDWARE.md`](docs/R36XX_HARDWARE.md).

---

## 📜 Credits & Acknowledgments

* **ChristianHaitian**: Creator and maintainer of the ArkOS and dArkOS operating systems.
* **PortMaster Team**: For native ARM open-source gaming runtime and ports.
* **R36S / Retro Handheld Community**: For display panel reverse engineering and hardware research.
