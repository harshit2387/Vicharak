# Shrike Lite RP2040 firmware

This Pico SDK C firmware embeds the MCU bitstream generated from the local `LED.ffpga` project and configures the Shrike Lite FPGA over SPI0 at startup.

The RP2040 user LED is on GPIO4 and blinks as a 1 Hz heartbeat. In Renesas Go Configure's I/O Planner, map `clk` to `OSC_CLK`, `clk_en` to `OSC_EN`, `LED` to `GPIO16_OUT`, and `LED_en` to `GPIO16_OE`. After changing `ffpga/src/main.v` or its I/O mapping, regenerate `FPGA_bitstream_MCU.bin` before rebuilding, or the UF2 will still contain the older FPGA design.

## Generate the FPGA bitstream

Open `D:\Vicharak\FPGA\MUX1\LED\LED.ffpga` in Renesas Go Configure Software Hub. In I/O Planner, map `clk` to `OSC_CLK`, `clk_en` to `OSC_EN`, `LED` to `GPIO16_OUT`, and `LED_en` to `GPIO16_OE`, then choose **Generate Bitstream**. The generated MCU file is:

`D:\Vicharak\FPGA\MUX1\LED\ffpga\build\bitstream\FPGA_bitstream_MCU.bin`

The Makefile uses that MCU file by default. The other files in that output directory are not the MCU bitstream. The selected file is converted into a C header during the build and embedded in the RP2040 UF2.

## Build and flash

Install/use CMake, Ninja, GNU Make, Python 3, and the Raspberry Pi Pico SDK. The Makefile defaults `PICO_SDK_PATH` to `C:/Users/sharm/pico-sdk`; override it if your SDK is elsewhere. Set `PYTHON` if Python is not on your PATH.

1. Generate the MCU bitstream from `LED.ffpga` as described above.
2. Hold BOOTSEL while connecting the Shrike Lite over USB so its `RPI-RP2` drive appears.
3. From this folder, run `make flash`.

The command builds `build/vicharak_firmware.uf2` and copies it to the BOOTSEL drive. After reboot, the RP2040 streams the embedded bitstream to the FPGA. To use a specific BOOTSEL drive letter, run `make flash BOARD_DRIVE=R:/`. To choose a different bitstream, set `BITSTREAM=...`.
