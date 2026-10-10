# Vicharak RP2040 & FPGA Development Workspace

A complete, multi-language, professional workspace layout designed for developing embedded firmware and hardware logic for the **Vicharak Shrike / Shrike-Lite** board (featuring the Raspberry Pi RP2040 microcontroller paired with a Renesas ForgeFPGA).

---

## 🚀 Workspace Directory Structure

```text
E:\Vicharak\
│
├── 01_FPGA\                  # FPGA Hardware Descriptions (Verilog / VHDL / Bitstreams)
│   ├── rtl\                  # Verilog HDL source modules (e.g., top.v)
│   ├── constraints\          # Pin mapping constraints (.pcf / .cst)
│   └── build\                # Synthesized bitstream outputs (.bin)
│
├── 02_RP2040_C\              # RP2040 C/C++ SDK Project Workspace
│   ├── src\                  # Main C/C++ source code (main.c)
│   ├── include\              # Custom header files
│   ├── ppi_bridge\           # FPGA-RP2040 parallel/SPI bridge driver code
│   └── CMakeLists.txt        # CMake build configuration file
│
├── 03_RP2040_Python\         # MicroPython / Python Control Scripts
│   ├── main.py               # Main MicroPython entry script for the board
│   ├── scripts\              # Python utilities & bitstream upload helpers
│   └── lib\                  # Helper libraries (SPI/I2C communication)
│
├── 04_Docs\                  # Documentation, pinouts, and references
│   └── datasheets\           # Renesas ForgeFPGA & RP2040 datasheets
│
├── 05_Tools\                 # Local toolchains, utilities, and flashing scripts
│   └── flash_scripts\        # Scripts to program the FPGA via RP2040
│
└── vicharak.code-workspace   # VS Code multi-root workspace file
