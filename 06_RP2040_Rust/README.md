# Shrike Lite FPGA flash firmware (Rust)

This is a standalone `no_std` Rust workspace for the Shrike Lite RP2040. It embeds the Renesas ForgeFPGA MCU bitstream in the RP2040 firmware and streams it to the FPGA over SPI0 during startup, matching the C firmware in `02_RP2040_C`.

## FPGA bitstream input

Generate `FPGA_bitstream_MCU.bin` from `D:\Vicharak\FPGA\MUX1\LED\LED.ffpga` in Renesas Go Configure. The default input expected by `build.rs` is:

`D:\Vicharak\FPGA\MUX1\LED\ffpga\build\bitstream\FPGA_bitstream_MCU.bin`

To use another file, set the `FPGA_BITSTREAM` environment variable before running `make`.

## Rust tools

Install Rust with rustup, then install the RP2040 target and UF2 converter:

```powershell
rustup target add thumbv6m-none-eabi
cargo install elf2uf2-rs --locked
```

GNU Make and Python 3 are also used by the Makefile. The project uses the upstream `rp-pico` board support package and `rp2040-hal` SPI implementation.

## Build and flash

From this folder:

```powershell
make build
make uf2
```

To flash, hold BOOTSEL while connecting the Shrike Lite over USB so the `RPI-RP2` drive appears, then run:

```powershell
make flash
```

The flash helper detects the `RPI-RP2` drive automatically. To specify its drive letter, use `make flash BOARD_DRIVE=R:/`.