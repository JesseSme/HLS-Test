#include <systemc.h>

#pragma hls_design top
SC_MODULE(spi_adxl_top) {
    sc_in<bool> CLK;
    sc_out<bool> SCLK;
    sc_out<bool> MOSI;
    sc_in<bool> MISO;
    sc_in<sc_lv<8> > DATA_IN;

    void sc_start_of_simulation(void) {
        SCLK->write(true);
        MOSI->write(true);
    }

    SC_CTOR(spi_adxl_top) {
        SC_METHOD(generate_sclk);
        // LED.initialize(0);
        sensitive << CLK.pos();
    }

    void generate_sclk();
};