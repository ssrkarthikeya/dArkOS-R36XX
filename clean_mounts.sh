#!/bin/bash
# ==============================================================================
# dArkOS Safe Build Mounts & Cache Cleaner
# ==============================================================================

echo "[*] Cleaning up build mounts and loop devices..."

# Unmount chroot binds safely
for m in Arkbuild/home/ark/Arkbuild_ccache Arkbuild/dev/pts Arkbuild/dev Arkbuild/proc Arkbuild/sys Arkbuild Arkbuild-final \
         Arkbuild32/home/ark/Arkbuild_ccache Arkbuild32/dev/pts Arkbuild32/dev Arkbuild32/proc Arkbuild32/sys Arkbuild32; do
  if grep -qs "$m" /proc/mounts; then
    sudo umount -l "$m" 2>/dev/null || true
  fi
done

# Detach all loop devices associated with ArkOS images
for loop in $(losetup -a | grep -E "ArkOS|dArkOS" | cut -d: -f1); do
  sudo losetup -d "$loop" 2>/dev/null || true
done

# Remove zero-byte or corrupted cache files if any
find Arkbuild_package_cache/ -maxdepth 1 -size 0 -delete 2>/dev/null || true
rm -f Arkbuild_package_cache/debian__rootfs.tar.gz 2>/dev/null || true

echo "[+] Mounts cleaned successfully."
