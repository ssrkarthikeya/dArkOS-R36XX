#!/bin/bash
# ==============================================================================
# Multi-Distro Host Environment & Build Dependencies Preparation
# ==============================================================================

echo -e "Making sure necessary host tools and ccache are available for the build....\n\n"

# Performance multi-core tuning
export MAKEFLAGS="-j$(nproc)"
export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)
export QEMU_CPU="cortex-a35"
export QEMU_RESERVED_VA="0x100000000"

if command -v apt-get &>/dev/null; then
  # --- DEBIAN / UBUNTU HOST ---
  if [ -z "$(dpkg --print-foreign-architectures 2>/dev/null | grep i386)" ]; then
    sudo dpkg --add-architecture i386 2>/dev/null || true
  fi
  sudo apt -y update
  for NEEDED_TOOL in bc btrfs-progs build-essential bison flex ccache curl debconf-utils debootstrap device-tree-compiler dosfstools e2fsprogs eatmydata gcc gdisk jq lib32stdc++6 libc6-i386 libncurses-dev libssl-dev lz4 lzop p7zip-full parted python-is-python3 qemu-user-static zlib1g:i386 xfsprogs pv dialog
  do
    if ! dpkg -s "$NEEDED_TOOL" &>/dev/null; then
      sudo apt -y install "${NEEDED_TOOL}" 2>/dev/null || true
    fi
  done

  # Ensure apt-cacher-ng if enabled
  if [[ "${ENABLE_CACHE}" == "y" ]]; then
    if ! dpkg -s apt-cacher-ng &>/dev/null; then
        echo "Installing apt-cacher-ng..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y apt-cacher-ng 2>/dev/null || true
        sudo sed -i "/\# AllowUserPorts:/c\AllowUserPorts: 0" /etc/apt-cacher-ng/acng.conf 2>/dev/null || true
        sudo sed -i "/\# DlMaxRetries: /c\DlMaxRetries: 50000" /etc/apt-cacher-ng/acng.conf 2>/dev/null || true
        sudo sed -i "/\# VfileUseRangeOps: /c\VfileUseRangeOps: 0" /etc/apt-cacher-ng/acng.conf 2>/dev/null || true
    fi
    sudo systemctl enable --now apt-cacher-ng 2>/dev/null || true
    sudo systemctl restart apt-cacher-ng 2>/dev/null || true
  fi

elif command -v pacman &>/dev/null; then
  # --- ARCH LINUX / MANJARO / ENDEAVOUROS HOST ---
  echo "[*] Arch Linux host detected."
  sudo pacman -S --needed --noconfirm \
    base-devel git coreutils parted util-linux e2fsprogs dosfstools \
    xz zstd curl wget dialog pv bc cmake \
    btrfs-progs bison flex ccache dtc gptfdisk jq lz4 lzop p7zip \
    debootstrap debian-archive-keyring ubuntu-keyring \
    qemu-user-static qemu-user-static-binfmt 2>/dev/null || true
  sudo systemctl restart systemd-binfmt 2>/dev/null || true

elif command -v dnf &>/dev/null; then
  # --- FEDORA / RHEL HOST ---
  echo "[*] Fedora/RHEL host detected."
  sudo dnf install -y \
    @development-tools cmake git coreutils parted util-linux e2fsprogs dosfstools \
    xz zstd curl wget dialog pv bc \
    btrfs-progs bison flex ccache dtc gdisk jq lz4 lzop p7zip p7zip-plugins \
    debootstrap qemu-user-static 2>/dev/null || true
fi

# Create ccache directory if it does not exist
mkdir -p Arkbuild_ccache
export CCACHE_DIR="${PWD}/Arkbuild_ccache"
if [ -x "/usr/sbin/update-ccache-symlinks" ]; then
  sudo /usr/sbin/update-ccache-symlinks 2>/dev/null || true
fi
[ -z "$(echo "$PATH" | grep ccache)" ] && export PATH="/usr/lib/ccache:$PATH"
