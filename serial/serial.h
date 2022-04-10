#ifndef __SERIAL_H__
#define __SERIAL_H__

#include "ac_channel.h"
#include "ac_fixed.h"
#include "ac_int.h"


typedef ac_int<16, false> uint16;

typedef ac_int<1, false> bit_t;
typedef ac_int<2, false> two_bits_t;
typedef ac_int<8, false> byte_t;
typedef ac_int<6, false> address_t;

/*
    <0> <1 2 3 4 5 6> <7 8 9 10 11 12 13 14>
    R/W..Address.......Data
*/
const int SERIAL_DATA_WIDTH = 15;
typedef ac_int<SERIAL_DATA_WIDTH,false> serial_data_t;

const int N_OF_ADXL = 1;

const int SCLK_FREQ = 5000000;
const int INT_CLK = 100000000;

typedef ac_int<ac::log2_ceil<(INT_CLK/SCLK_FREQ)/2>::val, false> half_clock_interval_t;
const half_clock_interval_t HALF_CLK_INTERVAL = (INT_CLK/SCLK_FREQ)/2;

void spi(bit_t do_write,
        bit_t &sclk_pin_out,
        bit_t miso_pins[N_OF_ADXL],
        bit_t mosi_pins[N_OF_ADXL]);

void spi_interface(serial_data_t &serial_data_in,
                byte_t &data_in,
                bit_t sclk_pin_out,
                bit_t miso_pin_in,
                bit_t mosi_pin_out);

void write_to_pin(bit_t out_bit, bit_t &out_pin);
byte_t read_from_pin(bit_t &in_byte, bit_t in_pin);

#endif
