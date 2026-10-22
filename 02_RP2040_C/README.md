# Shrike Lite RP2040 C firmware

Pico SDK firmware for the Shrike Lite. At startup, the RP2040 configures the on-board SLG47910 ForgeFPGA by sending `FPGA_bitstream_MCU.bin` over SPI0. It then blinks the RP2040 status LED as a heartbeat. The FPGA blink logic is supplied separately as Verilog and runs in the FPGA after configuration.

## Firmware and board signals

| Function | RP2040 GPIO | Notes |
| --- | ---: | --- |
| FPGA SPI MISO | 0 | SPI0 input |
| FPGA configuration chip select | 1 | GPIO controlled |
| FPGA SPI clock | 2 | SPI0 clock |
| FPGA SPI MOSI | 3 | SPI0 output |
| RP2040 user LED | 4 | Active high; 500 ms on/off heartbeat |
| FPGA power control | 12 | Sequenced by firmware |
| FPGA enable/reset control | 13 | Sequenced by firmware |
| FPGA user LED | FPGA GPIO16 | Driven by the loaded FPGA design |

The FPGA LED is active high. Its Verilog I/O Planner assignments are `clk → OSC_CLK`, `clk_en → OSC_EN`, `LED → GPIO16_OUT`, and `LED_en → GPIO16_OE`.

## FPGA bitstream prerequisite

The bitstream is generated from the local Renesas Go Configure project for `FPGA/MUX1/LED`. In Go Configure, synthesize the Verilog, assign the four mappings above, then choose **Generate Bitstream**. The firmware expects the MCU output at:

```text
../FPGA/MUX1/LED/ffpga/build/bitstream/FPGA_bitstream_MCU.bin
```

Run Go Configure again after changing the Verilog or I/O assignments. The C helper refuses to embed a bitstream older than `ffpga/src/main.v`. Other files in the bitstream output folder are not the MCU image. The Renesas project container is not distributed here because its embedded notice restricts redistribution; use your local project file to regenerate the bitstream.

## Prerequisites

- Raspberry Pi Pico SDK for RP2040
- CMake and Ninja
- GNU Make
- Python 3
- Renesas Go Configure, only when generating or changing the FPGA bitstream

The Makefile defaults `PICO_SDK_PATH` to `C:/Users/sharm/pico-sdk`. Override it for another SDK location. Set `PYTHON` if the Python executable is not named `python` or is not on `PATH`.

## Build

Open PowerShell in `02_RP2040_C` and run:

```powershell
make prepare-bitstream
make build
```

`make` runs the build target by default. The build converts the MCU bitstream into `build/generated/fpga_bitstream.h`, configures CMake, and creates:

```text
build/vicharak_firmware.uf2
```

To use a different generated MCU bitstream, pass its path to Make:

```powershell
make BITSTREAM="D:/path/to/FPGA_bitstream_MCU.bin"
```

## Flash the board

1. Hold the Shrike Lite **BOOTSEL** button while connecting it to USB.
2. Confirm the board appears as the `RPI-RP2` drive.
3. Run `make flash` from this folder. The helper detects the BOOTSEL drive, builds the UF2, and copies it there. The board reboots after the copy.

To specify the drive letter explicitly, for example `R:`, run:

```powershell
make flash BOARD_DRIVE=R:/
```

The project also checks in a built UF2 at `build/vicharak_firmware.uf2` as a ready-to-flash snapshot. Rebuild it whenever the C firmware or FPGA bitstream changes.

## Source files

- `src/main.c` — RP2040 startup, FPGA power/reset sequence, SPI bitstream transfer, and MCU LED heartbeat.
- `tools/embed_bitstream.py` — converts the MCU binary into a C header and checks its age against the Verilog source.
- `tools/flash_uf2.py` — finds the `RPI-RP2` drive and copies a UF2 to it.
- `CMakeLists.txt` — Pico SDK target and generated bitstream header build rule.
- `Makefile` — convenience targets for preparing the bitstream, building, and flashing.

For common errors and symptom checks, see [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).
