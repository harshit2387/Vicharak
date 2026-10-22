# Build from a Windows GNU Make prompt (or compatible make environment).
SHELL := cmd.exe
CMAKE ?= cmake
PYTHON ?= python
BUILD_DIR ?= build
BITSTREAM ?= ../FPGA/MUX1/LED/ffpga/build/bitstream/FPGA_bitstream_MCU.bin
PICO_SDK_PATH ?= C:\Users\sharm\pico-sdk
BOARD_DRIVE ?=

.PHONY: all prepare-bitstream configure build flash help

all: build

help:
	@echo Targets:
	@echo   make prepare-bitstream  Check the Renesas-generated MCU bitstream
	@echo   make build              Build RP2040 firmware and UF2
	@echo   make flash              Copy the UF2 to a Shrike Lite in BOOTSEL mode
	@echo Set BITSTREAM=... to use a different FPGA_bitstream_MCU.bin path.

prepare-bitstream:
	$(PYTHON) "tools/embed_bitstream.py" "$(BITSTREAM)" "$(BUILD_DIR)/generated/fpga_bitstream.h"

configure: prepare-bitstream
	$(CMAKE) -S . -B "$(BUILD_DIR)" -G Ninja -DPICO_SDK_PATH="$(PICO_SDK_PATH)" -DFPGA_BITSTREAM_FILE="$(abspath $(BITSTREAM))"

build: configure
	$(CMAKE) --build "$(BUILD_DIR)" --target vicharak_firmware

flash: build
	$(PYTHON) tools/flash_uf2.py "$(BUILD_DIR)/vicharak_firmware.uf2" $(if $(BOARD_DRIVE),--drive "$(BOARD_DRIVE)")
