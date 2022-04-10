#include "serial.h"

const bit_t data_in_bit = 1;


/*
    Takes in a byte, which it writes into the tx channel

    Baud is gonna be hardcoded

*/
#pragma hls_design top
void spi(bit_t do_write,
                    bit_t &sclk_pin_out,
                    bit_t miso_pins[N_OF_ADXL],
                    bit_t mosi_pins[N_OF_ADXL]) 
{
    bit_t old_do_write = 0;
    serial_data_t test = 21845;

    byte_t incoming_data = 0;
    bit_t sclk_pin_out_internal = 1;
    bit_t miso_pin_in = 0;
    bit_t mosi_pin_out = 0;

    if (do_write == 1 && old_do_write == 0) {
        old_do_write = 1;
        serial(test, incoming_data, sclk_pin_out, miso_pins[0], mosi_pins[0]);
    } else {
        old_do_write = 0;
    }

    incoming_data = 0;
}

#pragma hls_design block
void spi_interface(serial_data_t serial_data_in,
         byte_t data_in,
         bit_t &sclk_pin_out,
         bit_t miso_pin_in,
         bit_t &mosi_pin_out)
{
    serial_data_t tmp = 0;
    byte_t intmp = 0;
    bit_t data_in_bit = 1;
    sclk_pin_out = data_in_bit;

    bit_t r_or_w = 0;
    half_clock_interval_t counter = 0;
    ac_int<ac::log2_ceil<SERIAL_DATA_WIDTH>::val, false> bit_counter = 0;

    //Two sclks for edge detection
    bit_t sclk_b = 1;
    bit_t sclk_old = 1;

    tmp = serial_data_in;
    r_or_w = tmp[0];

    while (bit_counter != SERIAL_DATA_WIDTH) {

        /** SPI Clock **/
        if (counter != HALF_CLK_INTERVAL /* && ready_rw */) {
            counter++;
        /** End SPI Clock **/
        } 
        else 
        {
            counter = 0;
            
            /** Falling edge detect **/
            sclk_old = sclk_b;
            sclk_b = !sclk_b;
            sclk_pin_out = sclk_b;

            if (sclk_old && !sclk_b) {
                if (r_or_w == 0) {
                    mosi_pin_out = tmp[bit_counter];
                    // write_to_pin(tmp[bit_counter], mosi_pin_out);
                    // write_out_bit.write(tmp[bit_counter]);
                } 
                else 
                {
                    if (bit_counter < 7) {
                        mosi_pin_out = tmp[bit_counter];
                        // write_to_pin(tmp[bit_counter], mosi_pin_out);
                        // write_out_bit.write(tmp[bit_counter]);
                    }
                    else
                    {
                        intmp[bit_counter-7] = miso_pin_in;
                        // write_to_pin(data_in_bit, mosi_pin_out);
                        // write_out_bit.write(data_in_bit);
                    }   
                }
                // spi_counter_out.write(spi_counter);
                bit_counter++;
            }
            /** End Falling edge detect **/
        }
    }
    data_in = intmp;
}


/* 
void serial_hierarchical(ac_channel<serial_data_t > &data_in) {

    bit_t spi_clock = 1;
    int bit_counter = 0;

    if (serial_data_in.available(1)) {
        serial_data_in.read(tmp);
        r_or_w = tmp[0];
    } else {
        
    }
}

void falling_edge(bit_t &clock_out) {

    half_clock_interval_t counter = 0;
    bit_t sclk = 1;
    bit_t sclk_old = 1;
    int bit_counter = 0;

    while (bit_counter != SERIAL_DATA_WIDTH) {

        if (counter != HALF_CLK_INTERVAL) {
            counter++;
        // End BAUD Clock 
        } else {
            counter = 0;
            sclk_old = sclk;
            sclk != sclk;
            clock_out = sclk;
        }
    }
} 
 */
/* 
#pragma hls_design block
void write_to_pin(bit_t out_bit, bit_t &out_pin) {
    out_pin = out_bit;
}

#pragma hls_design block
byte_t read_from_pin(byte_t &in_byte, bit_t in_bit) {

    static int bit_position = 0;
    in_byte[bit_position] = in_bit;
    if (bit_position == 7) bit_position = 0;
    else bit_position++;

    return in_byte;
} */