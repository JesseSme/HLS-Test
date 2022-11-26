#include "ac_int.h"

// Types
typedef ac_int<1,false> wire_out;
typedef ac_int<1,false> bit;
const int buffer_size = 128;
const int maxBytes = buffer_size/8;

// Defaults for SPI
const int def_SCLK = 1;
const int def_ENABLE = 1;
const int def_SDI;
const int def_SDO = 1;

// Address stuff
const int address_length = 6;
typedef ac_int<8, false> byte;

template<int sensors, int CPOL, int CPHA, int sysCLK, int spiCLK>
class SPI
{
    private:
    ac_int<buffer_size, false> buffer = 0;
    ac_int<ac::log2_ceil<sysCLK/spiCLK>::val, false> spiCLKCycles = sysCLK/spiCLK;
    ac_int<ac::log2_ceil<(sysCLK/spiCLK)/2>::val, false> halfCLKCycles = sysCLK/spiCLK/2;
    wire_out &CS;
    wire_out &SCLK;
    wire_out &enable[sensors];
    wire_out &SDI[sensors];
    wire_out &SDO[sensors];
    bit busy = 0;
    


    public:
    SPI(wire_out &CS_pin, 
        wire_out &SCLK_pin, 
        wire_out &enable_pin[sensors], 
        wire_out &SDI_pin[sensors], 
        wire_out &SDO_pin[sensors])
    {
        CS = CS_pin;
        SCLK = SCLK_pin;
        enable = enable_pin; 
        SDI = SDI_pin;
        SDO = SDO_pin;

        CS = CPOL;
        SCLK = CPOL;
        enable = 1;
        ac
        SDI = 1;
        SDO = 1;
    }
    
    void write(byte address, int bytes, ){
        if (bytes <= maxBytes) {
            
        }
    }

};
