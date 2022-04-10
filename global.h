#ifndef __GLOBAL_H_
#define __GLOBAL_H_

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
    R/W  Address       Data
*/
typedef ac_int<15,false> serial_data_t;

#endif
