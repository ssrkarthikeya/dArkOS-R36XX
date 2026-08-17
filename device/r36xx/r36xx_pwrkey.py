#!/usr/bin/env python3
# ==============================================================================
# dArkOS-R36XX Graceful Power Key Daemon
# Catches RK817-1 PMIC Power Key events and performs clean sync & shutdown
# ==============================================================================

import os
import sys
import time
import evdev
from select import select

def find_pwrkey_device():
    devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
    for dev in devices:
        name_lower = dev.name.lower()
        if "pwrkey" in name_lower or "power" in name_lower or "rk8xx" in name_lower:
            return dev
    # Fallback to any device that emits KEY_POWER (code 116)
    for dev in devices:
        caps = dev.capabilities()
        if evdev.ecodes.EV_KEY in caps:
            if evdev.ecodes.KEY_POWER in caps[evdev.ecodes.EV_KEY]:
                return dev
    return None

def main():
    dev = None
    # Wait for input device on boot
    for _ in range(15):
        dev = find_pwrkey_device()
        if dev:
            break
        time.sleep(1)

    if not dev:
        sys.exit(0)

    press_time = 0

    while True:
        r, _, _ = select([dev], [], [], 1.0)
        if not r:
            continue

        for event in dev.read():
            if event.type == evdev.ecodes.EV_KEY and event.code == evdev.ecodes.KEY_POWER:
                if event.value == 1:  # Key down
                    press_time = time.time()
                elif event.value == 0:  # Key release
                    duration = time.time() - press_time
                    if duration >= 0.8:  # Intentional hold for 0.8s
                        os.system("sync; systemctl poweroff --no-wall")
                        sys.exit(0)

if __name__ == "__main__":
    main()
