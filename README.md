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
2. ⚡ **5V USB OTG & Networking**:
   - 5V USB OTG power boost enabled in DTB for Wi-Fi dongles and phone tethering.
   - Pre-bundled uncompressed Realtek Wi-Fi microcode (`RTL8188EUS`, `RTL8192EU`, `RTL8821CU`).
   - Plug-and-play Wi-Fi auto-configuration via `/boot/wifikey.txt`.
3. 🔊 **Clean High-Fidelity Audio**:
   - Calibrated ALSA audio state eliminating Wi-Fi RF ground buzz and idle hiss.
4. 🔋 **PMIC & Graceful Shutdown**:
   - Tuned ADC battery curve for the onboard **Rockchip RK817-1 PMIC**.
   - Dedicated power-key event daemon for clean, filesystem-safe shutdowns.
5. 🛡️ **SSH Auto-Enabled**:
   - SSH server enabled by default on port 22 (`ark` / `ark`).

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
