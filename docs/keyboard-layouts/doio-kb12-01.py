#!/usr/bin/env python3
"""Write the DOIO KB12-01 layer 0 keymap over VIA's raw HID interface.

Keys 1-12 (row by row, top-left first) become Ctrl+Alt+Shift+F13..F24 (QMK
MEH(KC_F13..KC_F24)). Dial presses and other layers are left alone. The keymap
lives in the pad's EEPROM, so this only needs re-running after a reset.

Needs read/write on the pad's /dev/hidraw node (the input group, or the udev
rule from run_onchange_after_setup-vial-udev.sh.tmpl).

Usage:
    python3 doio-kb12-01.py
"""
import glob
import os
import sys

COLS = 5  # 3x5 matrix; column 4 holds the dial presses
KEYS = [0, 1, 2, 3, 5, 6, 7, 8, 10, 11, 12, 13]  # matrix index of keys 1-12
MEH = 0x0700
KC_F13 = 0x68


def find_raw_hid():
    for node in glob.glob("/sys/class/hidraw/hidraw*"):
        uevent = open(f"{node}/device/uevent").read()
        desc = open(f"{node}/device/report_descriptor", "rb").read()
        if "HID_NAME=DOIO KB12-01" in uevent and desc.startswith(b"\x06\x60\xff"):
            return f"/dev/{os.path.basename(node)}"
    sys.exit("DOIO KB12-01 raw HID interface not found")


def cmd(fd, *b):
    os.write(fd, bytes(b) + bytes(32 - len(b)))
    return os.read(fd, 32)


fd = os.open(find_raw_hid(), os.O_RDWR)
for n, idx in enumerate(KEYS):
    row, col = divmod(idx, COLS)
    kc = MEH | (KC_F13 + n)
    cmd(fd, 0x05, 0, row, col, kc >> 8, kc & 0xFF)
    r = cmd(fd, 0x04, 0, row, col)
    got = r[4] << 8 | r[5]
    print(f"key {n + 1:2}: MEH(F{13 + n}) {'ok' if got == kc else f'FAILED, reads {got:#06x}'}")
