#include "spi_adxl.h"

int sc_main(int, char *[]) {
    sc_clock clk;
    sc_signal<bool> reset;
    sc_signal<bool> button_in;
    sc_signal<bool> led_out;

    sc_start();
    return 0;
}