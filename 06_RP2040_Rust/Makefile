CARGO ?= cargo
UF2_CONVERTER ?= elf2uf2-rs
PYTHON ?= python
TARGET ?= thumbv6m-none-eabi
APP ?= shrike_fpga_rust
ELF := target/$(TARGET)/release/$(APP)
UF2 := target/$(TARGET)/release/$(APP).uf2
FLASH_HELPER := tools/flash_uf2.py

.PHONY: all build uf2 flash clean help

all: uf2

help:
	@echo Targets:
	@echo   make build  Build the Shrike Lite RP2040 firmware ELF
	@echo   make uf2    Convert the ELF to an RP2040 UF2 file
	@echo   make flash  Copy the UF2 to the Shrike Lite BOOTSEL drive
	@echo Set FPGA_BITSTREAM before make to override the default MCU bitstream path.

build:
	$(CARGO) build --release

uf2: build
	$(UF2_CONVERTER) convert --family rp2040 "$(ELF)" "$(UF2)"

flash: uf2
	$(PYTHON) "$(FLASH_HELPER)" "$(UF2)" $(if $(BOARD_DRIVE),--drive "$(BOARD_DRIVE)")

clean:
	$(CARGO) clean