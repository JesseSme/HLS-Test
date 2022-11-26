#include "ac_int.h"

// Types
typedef ac_int<1,false> wire_out;
typedef ac_int<1,false> bit;
const int buffer_size = 128;
const int maxBytes = buffer_size/8;

// Channels
typedef ac_channel<ac_int<buffer_size,false> > SPI_out_channel_t;


// Defaults for SPI
const int def_SCLK = 1;
const int def_ENABLE = 1;
const int def_SDI;
const int def_SDO = 1;

// Address stuff
const int address_width = 6;
typedef ac_int<6, false> address_t;
typedef ac_int<8, false> byte_t;

template<int sensors, int CPOL, int CPHA, int sysCLK, int spiCLK>
class SPI
{
    private:
    ac_int<buffer_size, false> buffer[sensors] = 0;
    ac_int<ac::log2_ceil<sysCLK/spiCLK>::val, false> spiCLKCycles = sysCLK/spiCLK;
    ac_int<ac::log2_ceil<(sysCLK/spiCLK)/2>::val, false> halfCLKCycles = sysCLK/spiCLK/2;
    wire_out &CS;
    wire_out &SCLK;
    wire_out &enable[sensors];
    wire_out &SDI[sensors];
    wire_out &SDO[sensors];
    bit busy = 1;
    


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
        static tmp3 = ac::init_array<AC_VAL_0>(buffer, sensors);
        static tmp1 = ac::init_array<AC_VAL_MAX>(SDI, sensors);
        static tmp2 = ac::init_array<AC_VAL_MAX>(SDO, sensors);
    }
    
    int read(address_t address, int bytes, SPI_out_channel_t &data_out)
    {
        ac_int<ac::log2_ceil<(buffer_size+8)*2>::val, false> edge_counter = (buffer_size+8)*2;
        ac_int<ac::log2_ceil<halfCLKCycles>::val, false> halfCycleCounter = halfCLKCycles;
        byte_t address_counter = 16;
        byte_t deassertion_counter = 8;
        ac_int<8, false> data = AC_VAL_MAX;
        data.set_slc<address_width>(0,address);
        buffer = 0;
        if (busy) {
            return 0;
        } 
        else if (bytes <= maxBytes) 
        {
            CS = not CS;
            busy = not busy;
            while(edge_counter != 0) {
                if (halfCycleCounter == 0) {
                    SCLK = not SCLK;
                    edge_counter--;
                    if (address_counter != 0) {
                        enable = 1;
                        address_counter--;
                        #pragma hls_unroll
                        for (int i = 0; i < sensors; i++)
                            SDO[i] = address[address_counter/2];
                    } else {
                        enable = 0;
                        #pragma hls_unroll
                        for(int i = 0; i < sensors; i++)
                            buffer[i][edge_counter/2] = SDI[i];
                    }
                    halfCycleCounter = halfCLKCycles;

                } else {
                    halfCycleCounter--;
                }
            }
            while(deassertion_counter-- != 0);
            CS = not CS;
            busy = not busy;
        }
        data_out.write(buffer);
        return 1;
    }
    int write(address_t address, byte_t data) {
        ac_int<ac::log2_ceil<(16)*2>::val, false> edge_counter = (16)*2;
        ac_int<ac::log2_ceil<halfCLKCycles>::val, false> halfCycleCounter = halfCLKCycles;
        byte_t address_counter = 16;
        byte_t deassertion_counter = 8;
        ac_int<8, false> data = 0;
        data.set_slc<address_width>(0,address);
        buffer = 0;
        if (busy) {
            return 0;
        }
        else {
            CS = not CS;
            busy = not busy;
            while(edge_counter != 0) {
                if (halfCycleCounter == 0) {
                    SCLK = not SCLK;
                    edge_counter--;
                    enable = 1;
                    if (address_counter != 0) {
                        address_counter--;
                        #pragma hls_unroll
                        for(int i = 0; i < sensors; i++)
                            SDO[i] = address_counter[address_counter/2];
                    } else {
                        #pragma hls_unroll
                        for(int i = 0; i < sensors; i++)
                            SDO[i] = data[edge_counter/2];
                    }
                } else {
                    halfCycleCounter--;
                }
            }
        }
    }



};
