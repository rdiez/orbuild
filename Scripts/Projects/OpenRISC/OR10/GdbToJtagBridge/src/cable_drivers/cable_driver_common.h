
#ifndef CABLE_DRIVER_COMMON_H_INCLUDED
#define CABLE_DRIVER_COMMON_H_INCLUDED

#include <stdint.h>
#include <stddef.h>  // For NULL.

#include "cable_write_bit_constants.h"

struct jtag_cable_t
{
  const char *name;
  int (*inout_func)(uint8_t, uint8_t *);
  int (*out_func)(uint8_t);
  int (*init_func)();
  int (*opt_func)(int, const char *);
  int (*bit_out_func)(uint8_t);
  int (*bit_inout_func)(uint8_t, uint8_t *);
  int (*stream_out_func)(const uint32_t *, int, int);
  int (*stream_inout_func)(const uint32_t *, uint32_t *, int, int);
  int (*flush_func)();
  void (*close_func)();
  const char *opts;
  const char *help;

  jtag_cable_t ( void )
  : name( NULL )
  , inout_func( NULL )
  , out_func( NULL )
  , init_func( NULL )
  , opt_func( NULL )
  , bit_out_func( NULL )
  , bit_inout_func( NULL )
  , stream_out_func( NULL )
  , stream_inout_func( NULL )
  , flush_func( NULL )
  , close_func( NULL )
  , opts( NULL )
  , help( NULL )
  {
  }
};


// These should only be used in the cable_* files.
#define TCLK_BIT (0x01)
#define TRST_BIT (0x02)
#define TDI_BIT  (0x04)
#define TMS_BIT  (0x08)
#define TDO_BIT  (0x20)

// Common functions for lower-level drivers to use as desired.
int cable_common_write_bit ( uint8_t packet );
int cable_common_read_write_bit ( uint8_t packet_out, uint8_t * bit_in );
int cable_common_write_stream ( const uint32_t * stream, int len_bits, int set_last_bit );
int cable_common_read_stream ( const uint32_t *outstream, uint32_t *instream, int len_bits, int set_last_bit );

extern jtag_cable_t * jtag_cable_in_use;

#endif  // Include this header file only once.
