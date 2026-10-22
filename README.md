# Vicharak Shrike Lite: RP2040 + ForgeFPGA

Firmware and FPGA example for blinking the on-board Shrike Lite FPGA LED. The project pairs RP2040 firmware in C or Rust with Verilog for the SLG47910 ForgeFPGA. The RP2040 sends the generated FPGA MCU bitstream to the FPGA over SPI during startup; the FPGA then drives its own LED from its internal oscillator.

## Repository layout

- `FPGA/MUX1/LED/ffpga/src/main.v` — Verilog LED blink design.
- `FPGA/MUX1/LED/README.md` — FPGA pin mapping and bitstream generation steps.
- `02_RP2040_C/` — Pico SDK firmware, bitstream embedding, UF2 build, and BOOTSEL flash helper.
- `06_RP2040_Rust/` — `no_std` Rust firmware that sends the same bitstream over SPI, with UF2 and flash targets.

## FPGA blink design

The FPGA LED is GPIO16 and is active high. In Renesas Go Configure's I/O Planner, map `clk` to `OSC_CLK`, `clk_en` to `OSC_EN`, `LED` to `GPIO16_OUT`, and `LED_en` to `GPIO16_OE`. The Verilog counter uses the 50 MHz oscillator and toggles the LED about once per second.

Generate `FPGA_bitstream_MCU.bin` locally in Renesas Go Configure before building either firmware. Keep the generated file at `FPGA/MUX1/LED/ffpga/build/bitstream/FPGA_bitstream_MCU.bin` or set the project's bitstream override. Generated build outputs and UF2 files are excluded from Git; the firmware build embeds the local MCU bitstream into the RP2040 image.

The original Renesas `.ffpga` project container is not included because it contains a notice restricting redistribution. The Verilog source is included so it can be used in a locally created/opened Renesas project.

## Build and flash the C firmware

Install CMake, Ninja, GNU Make, Python 3, and the Raspberry Pi Pico SDK. From `02_RP2040_C`, run:

```powershell
make
```

This produces `02_RP2040_C/build/vicharak_firmware.uf2`. To flash, hold **BOOTSEL** while connecting the board, wait for the `RPI-RP2` drive, then run:

```powershell
make flash
```

The helper detects the `RPI-RP2` volume by its label. To specify its drive letter, use `make flash BOARD_DRIVE=R:/`.

## Build and flash the Rust firmware

Install Rust using rustup, then add the RP2040 target and UF2 converter:

```powershell
rustup target add thumbv6m-none-eabi
cargo install elf2uf2-rs --locked
```

From `06_RP2040_Rust`, run `make` to build the ELF and UF2. Hold **BOOTSEL** while connecting the board, then run `make flash` to copy it to `RPI-RP2`. Set `FPGA_BITSTREAM` to use a different local bitstream file.

## LEDs

- RP2040 heartbeat LED: GPIO4, blinked by the C firmware.
- FPGA user LED: GPIO16, blinked by the FPGA design after the RP2040 configures the FPGA.

The board must be connected in BOOTSEL mode for UF2 copying. Do not copy firmware to an unrelated removable drive.
