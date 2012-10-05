
#include "cable_driver_common.h"  // The include file for this module should come first.

#include <stddef.h>
#include <assert.h>


#include "../errcodes.h"
#include "../cable_api.h"


#define debug(...)   //fprintf(stderr, __VA_ARGS__ )


jtag_cable_t * jtag_cable_in_use = NULL; // The currently selected cable.


/////////////////////////////////////////////////////////////////////////////////////
// Common functions which may or may not be used by individual drivers

/* Note that these make no assumption as to the starting state of the clock,
 * and they leave the clock HIGH.  But, these need to interface with other routines (like
 * the byte-shift mode in the USB-Blaster), which begin by assuming that a new
 * data bit is available at TDO, which only happens after a FALLING edge of TCK.
 * So, routines which assume new data is available will need to start by dropping
 * the clock.
 */
int cable_common_write_bit ( const uint8_t packet  // See the TDO, TMS and TRST constants.
                           )
{
  uint8_t data = TRST_BIT;  // TRST is active low, don't clear unless /set/ in 'packet'
  int err = APP_ERR_NONE;

  /* Write data, drop clock */
  if(packet & TDO) data |= TDI_BIT;
  if(packet & TMS) data |= TMS_BIT;
  if(packet & TRST) data &= ~TRST_BIT;

  err |= jtag_cable_in_use->out_func(data);

  /* raise clock, to do write */
  err |= jtag_cable_in_use->out_func(data | TCLK_BIT);

  return err;
}

int cable_common_read_write_bit ( const uint8_t packet_out,  // See the TDO, TMS and TRST constants.
                                  uint8_t * const bit_in )
{
  uint8_t data = TRST_BIT;  //  TRST is active low, don't clear unless /set/ in 'packet'
  int err = APP_ERR_NONE;

  /* Write data, drop clock */
  if(packet_out & TDO) data |= TDI_BIT;
  if(packet_out & TMS) data |= TMS_BIT;
  if(packet_out & TRST) data &= ~TRST_BIT;

  err |= jtag_cable_in_use->out_func(data);  // drop the clock to make data available, set the out data
  err |= jtag_cable_in_use->inout_func((data | TCLK_BIT), bit_in);  // read in bit, clock high for out bit.

  return err;
}


// Writes bitstream via bit-bang. Can be used by any driver which does not have a high-speed transfer function.
// Transfers LSB to MSB of stream[0], then LSB to MSB of stream[1], etc.

int cable_common_write_stream ( const uint32_t * const stream,
                                const int len_bits,
                                const int set_last_bit )
{
  assert( len_bits > 0 );

  int index = 0;
  int bits_this_index = 0;
  uint8_t out;
  int err = APP_ERR_NONE;

  debug("writeStrm%d(", len_bits);

  for ( int i = 0; i < len_bits - 1; i++ )
  {
    out = (stream[index] >> bits_this_index) & 1;
    err |= cable_write_bit(out);
    debug("%i", out);
    bits_this_index++;
    if(bits_this_index >= 32)
    {
      index++;
      bits_this_index = 0;
    }
  }

  out = (stream[index] >>(len_bits - 1)) & 0x1;
  if(set_last_bit) out |= TMS;
  err |= cable_write_bit(out);
  debug("%i)\n", out);
  return err;
}

/* Gets bitstream via bit-bang.  Can be used by any driver which does not have a high-speed transfer function.
 * Transfers LSB to MSB of stream[0], then LSB to MSB of stream[1], etc.
 */
int cable_common_read_stream ( const uint32_t * const outstream,
                               uint32_t * const instream,
                               const int len_bits,
                               const int set_last_bit )
{
  assert( len_bits > 0 );

  int i;
  int index = 0;
  int bits_this_index = 0;
  uint8_t inval, outval;
  int err = APP_ERR_NONE;

  instream[0] = 0;

  debug("readStrm%d(", len_bits);
  for(i = 0; i < (len_bits - 1); i++)
  {
    outval = (outstream[index] >> bits_this_index) & 0x1;
    err |= cable_read_write_bit(outval, &inval);
    debug("%i", inval);
    instream[index] |= (inval << bits_this_index);
    bits_this_index++;
    if(bits_this_index >= 32)
    {
      index++;
      bits_this_index = 0;
      instream[index] = 0;  // It's safe to do this, because there's always at least one more bit
    }
  }

  if (set_last_bit)
    outval = ((outstream[index] >> (len_bits - 1)) & 1) | TMS;
  else
    outval = (outstream[index] >> (len_bits - 1)) & 1;

  err |= cable_read_write_bit(outval, &inval);
  debug("%i", inval);
  instream[index] |= (inval << bits_this_index);

  debug(") = 0x%lX\n", instream[0]);

  return err;
}
