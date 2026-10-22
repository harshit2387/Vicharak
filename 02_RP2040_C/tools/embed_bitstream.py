#!/usr/bin/env python3
"""Turn Renesas Go Configure's MCU bitstream into a C header."""

from pathlib import Path
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: embed_bitstream.py INPUT.bin OUTPUT.h", file=sys.stderr)
        return 2

    source = Path(sys.argv[1])
    output = Path(sys.argv[2])
    if not source.is_file():
        print(
            f"FPGA MCU bitstream not found: {source}\n"
            "Open the .ffpga project in Renesas Go Configure, map clk to OSC_CLK, "
            "clk_en to OSC_EN, LED to GPIO16_OUT, and LED_en to GPIO16_OE, "
            "then use Generate Bitstream. "
            "The expected output is ffpga/build/bitstream/FPGA_bitstream_MCU.bin.",
            file=sys.stderr,
        )
        return 1

    # Prevent silently packaging a bitstream generated before the current HDL.
    hdl = source.parent.parent.parent / "src" / "main.v"
    if hdl.is_file() and source.stat().st_mtime_ns < hdl.stat().st_mtime_ns:
        print(
            f"FPGA MCU bitstream is older than the HDL source: {source}\n"
            f"Regenerate the bitstream from {hdl} in Renesas Go Configure, "
            "then rerun make.",
            file=sys.stderr,
        )
        return 1

    data = source.read_bytes()
    if not data:
        print(f"FPGA MCU bitstream is empty: {source}", file=sys.stderr)
        return 1

    output.parent.mkdir(parents=True, exist_ok=True)
    rows = [data[index:index + 12] for index in range(0, len(data), 12)]
    body = "\n".join("    " + ", ".join(f"0x{byte:02x}" for byte in row) + "," for row in rows)
    header = (
        "/* Generated from the Renesas FPGA_bitstream_MCU.bin. Do not edit. */\n"
        "#ifndef FPGA_BITSTREAM_H\n#define FPGA_BITSTREAM_H\n"
        "#include <stdint.h>\n"
        "static const uint8_t fpga_bitstream[] __attribute__((aligned(4))) = {\n"
        f"{body}\n}};\n"
        "static const unsigned int fpga_bitstream_size = sizeof(fpga_bitstream);\n"
        "#endif\n"
    )
    output.write_text(header, encoding="ascii", newline="\n")
    print(f"Embedded {len(data)} bytes from {source} into {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
