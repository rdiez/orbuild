/* cable_common.c -- Interface to the low-level cable drivers
   Copyright (C) 2001 Marko Mlinar, markom@opencores.org
   Copyright (C) 2004 György Jeney, nog@sdf.lonestar.org
   Copyright (C) 2008 - 2010 Nathan Yawn, nathan.yawn@opencores.org

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "cable_api.h"  // The include file for this module should come first.

#include <stdio.h>
#include <string.h>
#include <assert.h>

#include <stdexcept>

#include "cable_drivers/cable_simulation_over_tcp_socket.h"
#include "cable_drivers/cable_simulation_with_predefined_file.h"

#ifdef __SUPPORT_PARALLEL_CABLES__
  #include "cable_drivers/cable_parallel.h"
#endif

#ifdef __SUPPORT_USB_CABLES__
  #include "cable_drivers/cable_usbblaster.h"
  #include "cable_drivers/cable_xpc_dlc9.h"

  #ifdef __SUPPORT_FTDI_CABLES__
   #include "cable_drivers/cable_ft245.h"
   #include "cable_drivers/cable_ft2232.h"
  #endif
#endif

#include "errcodes.h"
#include "string_utils.h"

#define debug(...)   //fprintf(stderr, __VA_ARGS__ )


#define JTAG_MAX_CABLES 16  // Actually 15, for the last element must be NULL.

static jtag_cable_t *jtag_cables[JTAG_MAX_CABLES];


/////////////////////////////////////////////////////////////////////////////////////
// Cable subsystem / init functions

void cable_setup ( void )
{
  for ( int j = 0; j < JTAG_MAX_CABLES; ++j )
    jtag_cables[ j ] = NULL;

  int i = 0;

  jtag_cables[i++] = cable_rtl_get_driver();
  jtag_cables[i++] = cable_vpi_get_driver();

#ifdef __SUPPORT_PARALLEL_CABLES__
  jtag_cables[i++] = cable_xpc3_get_driver();
  jtag_cables[i++] = cable_bb2_get_driver();
  jtag_cables[i++] = cable_xess_get_driver();
#endif

#ifdef  __SUPPORT_USB_CABLES__
  jtag_cables[i++] = cable_usbblaster_get_driver();
  jtag_cables[i++] = cable_xpcusb_get_driver();
 #ifdef __SUPPORT_FTDI_CABLES__
  jtag_cables[i++] = cable_ftdi_get_driver();
  jtag_cables[i++] = cable_ft245_get_driver();
 #endif
#endif

  assert( i < JTAG_MAX_CABLES );  // The last element must be NULL.
}


// Selects a cable for use.

bool cable_select ( const char * const cable_name )
{
  for ( int i = 0; jtag_cables[i] != NULL; i++ )
  {
    if( !strcmp( cable_name, jtag_cables[i]->name ) )
    {
      jtag_cable_in_use = jtag_cables[i];
      return true;
    }
  }

  return false;
}


void cable_init ( void )
{
  int err_code;

  try
  {
    err_code = jtag_cable_in_use->init_func();
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error initializing JTAG cable \'%s\': %s",
                                          jtag_cable_in_use->name,
                                          e.what() ) );
  }

  // Older code does not throw exceptions, but returns some error code,
  // so convert it to an exception here.
  if ( err_code != APP_ERR_NONE )
    throw std::runtime_error( format_msg( "Failed to initialize JTAG cable \'%s\'.",
                                          jtag_cable_in_use->name ) );
}


void cable_close ( void )
{
  if ( jtag_cable_in_use->close_func != NULL )
    jtag_cable_in_use->close_func();
}

// Parses command-line options specific to the selected cable.
void cable_parse_opt ( const int c, char * const str )
{
  if ( jtag_cable_in_use->opt_func( c, str ) != APP_ERR_NONE )
  {
      throw std::runtime_error( format_msg( "Failed to parse cable option '-%c %s'.", c, str ) );
  }
}

const char *cable_get_args()
{
  if(jtag_cable_in_use != NULL)
    return jtag_cable_in_use->opts;
  else
    return NULL;
}

// Prints a (short) usage message for each available cable.
void cable_print_help()
{
  int i;
  printf("Available cables: ");

  for(i = 0; jtag_cables[i]; i++)
  {
    if(i)
      printf(", ");
    printf("%s", jtag_cables[i]->name);
  }

  printf("\n\nOptions available for the JTAG cables:\n");
  for(i = 0; jtag_cables[i]; i++)
  {
    if(!jtag_cables[i]->help)
    {
      assert( false );  // All cables should have some help text.
      continue;
    }
    printf("\n  %s:\n\%s", jtag_cables[i]->name, jtag_cables[i]->help);
  }
}


/////////////////////////////////////////////////////////////////////////////////
// Cable API Functions

int cable_write_stream ( const uint32_t * stream, int len_bits, int set_last_bit )
{
  return jtag_cable_in_use->stream_out_func( stream, len_bits, set_last_bit );
}

int cable_read_write_stream ( const uint32_t * outstream, uint32_t * instream, int len_bits, int set_last_bit )
{
  return jtag_cable_in_use->stream_inout_func( outstream, instream, len_bits, set_last_bit );
}

// This function generates a complete TCLK clock cycle:
//   1)  TCLK=0, TRST=x, TMS=x, TDI=x
//   2)  TCLK=1, TRST=x, TMS=x, TDI=x
int cable_write_bit ( uint8_t packet  // See the TDO, TMS and TRST constants.
                    )
{
  return jtag_cable_in_use->bit_out_func( packet );
}

// For information about this routine's write behaviour, see cable_write_bit().
int cable_read_write_bit ( uint8_t packet_out,  // See the TDO, TMS and TRST constants.
                           uint8_t * bit_in )
{
  return jtag_cable_in_use->bit_inout_func( packet_out, bit_in );
}

int cable_flush(void)
{
  if(jtag_cable_in_use->flush_func != NULL)
    return jtag_cable_in_use->flush_func();
  return APP_ERR_NONE;
}
