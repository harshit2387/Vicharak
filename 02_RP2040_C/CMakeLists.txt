cmake_minimum_required(VERSION 3.13)
include(pico_sdk_import.cmake)

project(vicharak_firmware C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

set(FPGA_BITSTREAM_FILE
    "${CMAKE_CURRENT_SOURCE_DIR}/../FPGA/MUX1/LED/ffpga/build/bitstream/FPGA_bitstream_MCU.bin"
    CACHE FILEPATH "Renesas Go Configure MCU bitstream for Shrike Lite")
if(NOT EXISTS "${FPGA_BITSTREAM_FILE}")
    message(FATAL_ERROR
        "FPGA MCU bitstream not found: ${FPGA_BITSTREAM_FILE}\n"
        "Generate it in Renesas Go Configure, then run make again.")
endif()

find_package(Python3 REQUIRED COMPONENTS Interpreter)
pico_sdk_init()

set(FPGA_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
set(FPGA_BITSTREAM_HEADER "${FPGA_GENERATED_DIR}/fpga_bitstream.h")
add_custom_command(
    OUTPUT "${FPGA_BITSTREAM_HEADER}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${FPGA_GENERATED_DIR}"
    COMMAND "${Python3_EXECUTABLE}"
            "${CMAKE_CURRENT_SOURCE_DIR}/tools/embed_bitstream.py"
            "${FPGA_BITSTREAM_FILE}"
            "${FPGA_BITSTREAM_HEADER}"
    DEPENDS "${FPGA_BITSTREAM_FILE}"
            "${CMAKE_CURRENT_SOURCE_DIR}/tools/embed_bitstream.py"
    VERBATIM)

add_executable(vicharak_firmware src/main.c "${FPGA_BITSTREAM_HEADER}")
target_include_directories(vicharak_firmware PRIVATE "${FPGA_GENERATED_DIR}")
target_link_libraries(vicharak_firmware pico_stdlib hardware_spi hardware_i2c)
pico_enable_stdio_usb(vicharak_firmware 1)
pico_enable_stdio_uart(vicharak_firmware 0)
pico_add_extra_outputs(vicharak_firmware)