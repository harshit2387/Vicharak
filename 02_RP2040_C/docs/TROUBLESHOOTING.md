# C firmware troubleshooting

## `FPGA MCU bitstream not found`

Generate a bitstream in Renesas Go Configure and check that this exact file exists:

```text
FPGA/MUX1/LED/ffpga/build/bitstream/FPGA_bitstream_MCU.bin
```

The C project needs the **MCU** bitstream. Do not use the OTP, FLASH_MEM, or top-level `FPGA_bitstream.bin` output instead. If the file is stored elsewhere, pass its full path with `make BITSTREAM="..."`.

## `FPGA MCU bitstream is older than the HDL source`

The Verilog source was changed after the currently generated bitstream. Open the local Renesas project, synthesize, confirm the I/O mappings, choose **Generate Bitstream**, then run `make` again.

## The RP2040 LED blinks but the FPGA LED does not

The MCU LED and FPGA LED are controlled independently. The MCU heartbeat proves the RP2040 firmware is running, but does not prove FPGA configuration succeeded. Check these steps:

1. Confirm the UF2 was rebuilt after the most recent FPGA bitstream generation.
2. Confirm Go Configure mapped `clk` to `OSC_CLK`, `clk_en` to `OSC_EN`, `LED` to `GPIO16_OUT`, and `LED_en` to `GPIO16_OE`.
3. Confirm the generated file is `FPGA_bitstream_MCU.bin` and that Go Configure reported PNR complete.
4. Hold BOOTSEL and copy the latest `build/vicharak_firmware.uf2` to the board's `RPI-RP2` drive.

GPIO16 is the Shrike Lite FPGA user LED; GPIO4 is the RP2040 user LED. A solid LED alone does not identify whether the output mapping, clock mapping, or loaded bitstream is the cause.

## `python` or `make` is not recognized

Install Python 3 and GNU Make, then restart PowerShell so updated PATH settings are loaded. If Python has a different command name, set it explicitly for a build, for example:

```powershell
make PYTHON="C:/Path/To/python.exe"
```

## BOOTSEL drive not found

Hold BOOTSEL while connecting the board and check File Explorer for a drive named `RPI-RP2`. The flash helper only copies to that volume label by default. You can pass the drive explicitly with `make flash BOARD_DRIVE=R:/` after confirming the correct drive letter.
