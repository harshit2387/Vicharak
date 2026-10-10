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





🛠️ Hardware Overview: Vicharak Shrike Architecture
The Vicharak board bridges a dual-core ARM Cortex-M0+ microcontroller with programmable fabric:

Raspberry Pi RP2040 (02_RP2040_C & 03_RP2040_Python):

Runs core application firmware.

Handles USB/UART communication and sensor interfaces.

Manages bitstream programming and high-speed data bridging with the onboard FPGA.

Renesas ForgeFPGA (01_FPGA):

Provides programmable logic fabric for low-latency hardware acceleration.

Executes custom pin mappings, hardware PWM generators, and parallel processing pipelines.

📂 Why Build Folders Are Excluded from Git (.gitignore)
In the GitHub repository, folders such as 02_RP2040_C/build/, intermediate object files (.obj, .o), executable ELF files, UF2 images, and CMake configuration logs are intentionally excluded using .gitignore.

Detailed Explanation:
Separation of Source and Artifacts: Version control systems like Git are designed exclusively to track human-authored source files (such as main.c, top.v, main.py, and CMakeLists.txt). Machine-generated files are strictly compilation outputs.

Repository Size & Cleanliness: Building with the Raspberry Pi Pico SDK and Ninja creates hundreds of temporary cache and toolchain dependency files. Excluding them keeps the repository lightweight (a few kilobytes instead of hundreds of megabytes) and fast to clone.

Environment Independence: Build cache files contain host-specific absolute file system paths (e.g., E:/Vicharak/02_RP2040_C/build/...). Committing these paths would break compilation on other machines or operating systems.

Reproducible Local Builds: Build binaries can be generated cleanly on demand anytime by running the Ninja build pipeline.

💻 Getting Started & Development Guide
1. Opening the Unified Workspace in VS Code
To manage C/C++, Verilog, and MicroPython simultaneously:

Launch Visual Studio Code.

Navigate to File > Open Workspace from File....

Select E:\Vicharak\vicharak.code-workspace.

2. Building RP2040 C/C++ Firmware (02_RP2040_C)
To compile the RP2040 firmware into a deployable .uf2 binary:

PowerShell
# Navigate to the RP2040 C folder
cd E:\Vicharak\02_RP2040_C

# Ensure build folder exists
if (!(Test-Path "build")) { New-Item -ItemType Directory -Name "build" }
cd build

# Set the SDK path environment variable
$env:PICO_SDK_PATH = "C:\Users\sharm\pico-sdk"

# Run CMake generator
cmake -G "Ninja" -DCMAKE_TOOLCHAIN_FILE="$env:PICO_SDK_PATH\cmake\preload\toolchains\pico_arm_cortex_m0plus_gcc.cmake" ..

# Execute build
ninja
Flashing the Firmware:
Connect the Vicharak board to your computer while holding down the BOOTSEL button.

Release the button when the RPI-RP2 drive appears in File Explorer.

Drag and drop vicharak_firmware.uf2 from 02_RP2040_C/build/ onto the RPI-RP2 drive.

3. Developing FPGA Logic (01_FPGA)
Hardware description files should be placed inside 01_FPGA/rtl/ (e.g., top.v).

Use the Renesas ForgeFPGA Workshop synthesis toolchain to synthesize and generate bitstreams into 01_FPGA/build/.

📦 Version Control Workflow
To commit and push future code modifications to GitHub:

Bash
# Check modified files
git status

# Stage changes
git add .

# Commit with a descriptive message
git commit -m "feat: add SPI communication bridge between RP2040 and FPGA"

# Push to GitHub
git push origin main

---

### Push this README to GitHub

Run these commands in your Git Bash terminal to sync your updated `README.md` to GitHub:

```bash
git add README.md
git commit -m "docs: add comprehensive README documentation"
git push origin main
