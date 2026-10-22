#include <stdbool.h>
#include <stdio.h>

#include "hardware/gpio.h"
#include "hardware/spi.h"
#include "pico/stdlib.h"

#include "fpga_bitstream.h"

/* Shrike Lite FPGA configuration pins (RP2040 SPI0). */
enum {
    MCU_USER_LED = 4,
    FPGA_SPI_MISO = 0,
    FPGA_SPI_CS   = 1,
    FPGA_SPI_SCK  = 2,
    FPGA_SPI_MOSI = 3,
    FPGA_PWR      = 12,
    FPGA_EN       = 13,
};

static bool configure_fpga(void) {
    gpio_init(FPGA_PWR);
    gpio_init(FPGA_EN);
    gpio_init(FPGA_SPI_CS);
    gpio_set_dir(FPGA_PWR, GPIO_OUT);
    gpio_set_dir(FPGA_EN, GPIO_OUT);
    gpio_set_dir(FPGA_SPI_CS, GPIO_OUT);

    /* Follow the Shrike FPGA reset sequence: assert reset/power-off first. */
    gpio_put(FPGA_SPI_CS, 0);
    gpio_put(FPGA_EN, 0);
    gpio_put(FPGA_PWR, 0);
    sleep_ms(100);

    gpio_put(FPGA_EN, 1);
    gpio_put(FPGA_PWR, 1);
    sleep_ms(100);

    spi_init(spi0, 1600000);
    spi_set_format(spi0, 8, SPI_CPOL_0, SPI_CPHA_0, SPI_MSB_FIRST);
    gpio_set_function(FPGA_SPI_MISO, GPIO_FUNC_SPI);
    gpio_set_function(FPGA_SPI_SCK, GPIO_FUNC_SPI);
    gpio_set_function(FPGA_SPI_MOSI, GPIO_FUNC_SPI);

    /* Allow the FPGA configuration port to settle before starting SPI. */
    sleep_ms(500);
    gpio_put(FPGA_SPI_CS, 1);
    sleep_us(2000);
    gpio_put(FPGA_SPI_CS, 0);
    const int written = spi_write_blocking(spi0, fpga_bitstream,
                                          (int)fpga_bitstream_size);
    gpio_put(FPGA_SPI_CS, 1);
    sleep_ms(100);

    return written == (int)fpga_bitstream_size;
}

int main(void) {
    stdio_init_all();

    /* The Shrike Lite RP2040 user LED is active-high on GPIO4. */
    gpio_init(MCU_USER_LED);
    gpio_set_dir(MCU_USER_LED, GPIO_OUT);
    gpio_put(MCU_USER_LED, 0);

    const bool configured = configure_fpga();
    printf("FPGA bitstream: %s (%u bytes)\n",
           configured ? "sent" : "transfer failed",
           (unsigned)fpga_bitstream_size);

    while (true) {
        /* Keep a visible heartbeat even if FPGA configuration fails. */
        gpio_put(MCU_USER_LED, 1);
        sleep_ms(500);
        gpio_put(MCU_USER_LED, 0);
        sleep_ms(500);
    }
}
