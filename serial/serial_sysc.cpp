#include <systemc.h>

SC_MODULE(top) {
    sc_in<bool> CLK;
    sc_in<bool> BUTTON_IN;
    sc_out<bool> LED;

    SC_CTOR(top) {
        SC_METHOD(switchLed);
        dont_initialize();
        // LED.initialize(0);
        sensitive << CLK.pos();
    }

    void switchLed();
};

void top::switchLed() {
    LED->write(BUTTON_IN);
}


int sc_main(int, char *[]) {
    sc_clock clk;
    sc_signal<bool> reset;
    sc_signal<bool> button_in;
    sc_signal<bool> led_out;

    sc_start();
    return 0;
}