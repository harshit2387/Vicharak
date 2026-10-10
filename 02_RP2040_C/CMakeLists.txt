cmake_minimum_required(VERSION 3.13)
include(pico_sdk_import.cmake)

project(vicharak_firmware C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

add_executable(vicharak_firmware src/main.c)
target_link_libraries(vicharak_firmware pico_stdlib hardware_spi hardware_i2c)
pico_enable_stdio_usb(vicharak_firmware 1)
pico_enable_stdio_uart(vicharak_firmware 0)
pico_add_extra_outputs(vicharak_firmware)
