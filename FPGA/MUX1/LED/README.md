# Shrike Lite FPGA LED blink

This Verilog design blinks the FPGA's on-board GPIO16 LED using the SLG47910 internal 50 MHz oscillator. The output changes state at 50 million clock cycles, approximately once per second.

## I/O Planner mapping

| Verilog port | ForgeFPGA function | Purpose |
| --- | --- | --- |
| `clk` | `OSC_CLK` | Internal oscillator clock |
| `clk_en` | `OSC_EN` | Enable the oscillator |
| `LED` | `GPIO16_OUT` | FPGA user LED output |
| `LED_en` | `GPIO16_OE` | Enable GPIO16 output |

## Generate the MCU bitstream

1. Open the local Renesas Go Configure project for this design or create a ForgeFPGA project for SLG47910.
2. Use `ffpga/src/main.v` as the top-level Verilog source.
3. Synthesize, assign the I/O mappings above, and choose **Generate Bitstream**.
4. Confirm the tool creates `ffpga/build/bitstream/FPGA_bitstream_MCU.bin`.
5. From the repository root, build either `02_RP2040_C` or `06_RP2040_Rust`. Each embeds the MCU bitstream into its firmware image.

The Renesas `.ffpga` project container is not distributed in this repository because its embedded notice restricts redistribution. Keep and use the local project file with the Renesas toolchain.
