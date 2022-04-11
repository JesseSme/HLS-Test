#include "spi_adxl_top.h"

void spi_adxl_top::generate_sclk() {
    MOSI->write(MISO);
}



