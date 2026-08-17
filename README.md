# 🎮 dArkOS-R36XX MultiPanel

> **Modern 64-bit Debian 13 (Trixie) Linux Distribution Tailored Specifically for R36S & R36XX Clone Handheld Gaming Consoles (Rockchip RK3326).**

[![GitHub Repository](https://img.shields.io/badge/GitHub-ssrkarthikeya%2FdArkOS--R36XX-blue?style=flat-square&logo=github)](https://github.com/ssrkarthikeya/dArkOS-R36XX)
[![Debian Version](https://img.shields.io/badge/Debian-13%20(Trixie)-red?style=flat-square&logo=debian)](https://www.debian.org/)
[![SoC](https://img.shields.io/badge/SoC-Rockchip%20RK3326-orange?style=flat-square)](https://www.rock-chips.com/)
[![License](https://img.shields.io/badge/License-GPL%20%2F%20MIT-green?style=flat-square)](LICENSES.md)

---

## 🌟 Overview & Key Features

**dArkOS-R36XX** builds upon the official work of `christianhaitian/dArkOS`, introducing native hardware adaptation for the **R36S / R36XX** series of handheld consoles:

1. 📱 **Multi-Panel Display Support**:
   - Out-of-the-box compatibility with **Panel 1 through Panel 8** screens.
   - Pre-configured with the verified **Panel 4** display timing and initialization tree.
2. 🔋 **PMIC & Battery Calibration**:
   - Tuned ADC voltage profiles specifically for the onboard **Rockchip RK817-1 PMIC**.
   - Fixed LED indicators (Single Blue power indicator + Red charging indicator).
3. ⚡ **Modern Debian 13 (Trixie) Userspace**:
   - Multiarch **64-bit (arm64)** and **32-bit (armhf)** userspace.
   - Access to over 64,000+ official Debian packages via `apt`.
   - **Mesa 24.x Panfrost** GPU acceleration for Mali-G31 MP2.
4. 🕹️ **PortMaster & Standalone Emulators**:
   - Native support for PortMaster game ports (Celeste, SM64, Cave Story, Stardew Valley, etc.).
   - Optimized standalone builds of **DuckStation, PPSSPP, Flycast, Drastic, and Mupen64Plus-Next**.

---

## 🛠️ Building dArkOS for R36XX

### Recommended Build Environment
* **OS:** Ubuntu 24.04 LTS (Noble) x86_64 or modern Linux distro.
* **Storage:** 50+ GB free NVMe/SSD space.
* **Privileges:** `sudo` access (used for `debootstrap` and rootfs mounting).

### Quick Build

```bash
# Clone the repository
git clone https://github.com/ssrkarthikeya/dArkOS-R36XX.git
cd dArkOS-R36XX

# Run the dedicated R36XX build engine
./build_r36xx.sh
```

---

## 📦 Flashing to MicroSD Card

1. Download or locate your generated `dArkOS_R36XX_trixie.img`.
2. Flash to MicroSD (Slot 1 - Right Side / OS) using `dd` or Raspberry Pi Imager:
   ```bash
   sudo dd if=dArkOS_R36XX_trixie.img of=/dev/sdX bs=4M status=progress conv=fsync
   ```
3. Insert into the R36S console and power on!

---

## 📜 Credits & Acknowledgments

* **ChristianHaitian**: Creator and visionary behind the ArkOS and dArkOS operating systems.
* **PortMaster Team**: For native arm64/armhf open-source gaming runtime.
* **R36S / Retro Gaming Community**: For display panel reverse engineering and hardware research.
