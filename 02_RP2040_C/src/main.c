#include <stdio.h>
#include "pico/stdlib.h"

int main() {
    stdio_init_all();
    printf("Vicharak RP2040 + FPGA Workspace Ready!\n");
    while (true) {
        tight_loop_contents();
    }
    return 0;
}
