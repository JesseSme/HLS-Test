#include <iostream>
#include <time.h>
#include <stdlib.h>

#include "mc_scverify.h"
#include "serial.h"

int ret = 0;
int counter = 0;
bit_t tmp = 0;
int baud_counter = 0;
int data_tmp = 0;
int data_in;
serial_data_t test = 21845;


byte_t incoming_data = 0;
bit_t sclk_pin_out = 1;
bit_t miso_pin_in;
bit_t mosi_pin_out;



CCS_MAIN(int argc, char *argv[])
{
    FILE* output = fopen("serial_test_timing.txt", "w+");

    CCS_DESIGN(serial_interface)(test, incoming_data, sclk_pin_out, miso_pin_in, mosi_pin_out);

    printf("Data out: %d", (int)incoming_data);

    CCS_RETURN(ret);
}