#!/usr/bin/env python3
"""Copy an RP2040 UF2 onto the Shrike Lite BOOTSEL drive on Windows."""

import argparse
import ctypes
import shutil
import string
import sys
from pathlib import Path


def find_bootsel_drive() -> Path | None:
    if sys.platform != "win32":
        return None

    kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
    get_drives = kernel32.GetLogicalDrives
    get_drives.restype = ctypes.c_uint32
    get_volume = kernel32.GetVolumeInformationW
    get_volume.argtypes = [
        ctypes.c_wchar_p, ctypes.c_wchar_p, ctypes.c_uint32,
        ctypes.POINTER(ctypes.c_uint32), ctypes.POINTER(ctypes.c_uint32),
        ctypes.POINTER(ctypes.c_uint32), ctypes.c_wchar_p, ctypes.c_uint32,
    ]
    get_volume.restype = ctypes.c_int

    mask = get_drives()
    for index, letter in enumerate(string.ascii_uppercase):
        if not mask & (1 << index):
            continue
        root = f"{letter}:\\"
        label = ctypes.create_unicode_buffer(261)
        serial = ctypes.c_uint32()
        max_component = ctypes.c_uint32()
        flags = ctypes.c_uint32()
        filesystem = ctypes.create_unicode_buffer(261)
        ok = get_volume(root, label, len(label), ctypes.byref(serial),
                        ctypes.byref(max_component), ctypes.byref(flags),
                        filesystem, len(filesystem))
        if ok and label.value.upper() == "RPI-RP2":
            return Path(root)
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("uf2", type=Path, help="RP2040 firmware UF2")
    parser.add_argument("--drive", help="BOOTSEL drive root, for example R:/")
    args = parser.parse_args()

    if not args.uf2.is_file():
        print(f"Firmware UF2 not found: {args.uf2}", file=sys.stderr)
        return 1

    drive = Path(args.drive) if args.drive else find_bootsel_drive()
    if drive is None:
        print(
            "Shrike Lite BOOTSEL drive (RPI-RP2) was not found. Hold BOOTSEL "
            "while connecting the board, then retry. You can also pass "
            "--drive R:/ or make flash BOARD_DRIVE=R:/.",
            file=sys.stderr,
        )
        return 1
    if not drive.is_dir():
        print(f"BOOTSEL drive is not accessible: {drive}", file=sys.stderr)
        return 1

    destination = drive / args.uf2.name
    shutil.copyfile(args.uf2, destination)
    print(f"Copied {args.uf2} to {destination}. The board will reboot and run the firmware.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())