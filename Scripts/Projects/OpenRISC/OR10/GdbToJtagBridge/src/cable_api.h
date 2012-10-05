
#ifndef CABLE_API_H_INCLUDED
#define CABLE_API_H_INCLUDED

#include <stdint.h>

#include "cable_drivers/cable_write_bit_constants.h"


// Subsystem / init routines.
void cable_setup( void );
bool cable_select ( const char * cable_name );
void cable_init ( void );
void cable_close ( void );
void cable_parse_opt ( int c, char *str );
const char * cable_get_args();
void cable_print_help();


// API routines.
int cable_write_bit ( uint8_t packet );
int cable_read_write_bit ( uint8_t packet_out, uint8_t * bit_in );
int cable_write_stream ( const uint32_t * stream, int len_bits, int set_last_bit );
int cable_read_write_stream ( const uint32_t * outstream, uint32_t * instream, int len_bits, int set_last_bit );
int cable_flush ( void );

#endif  // Include this header file only once.
