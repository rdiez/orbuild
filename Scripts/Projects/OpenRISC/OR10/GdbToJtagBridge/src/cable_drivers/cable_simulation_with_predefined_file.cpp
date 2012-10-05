/* cable_sim.c - Simulation connection drivers for the Advanced JTAG Bridge
   Copyright (C) 2001 Marko Mlinar, markom@opencores.org
   Copyright (C) 2004 György Jeney, nog@sdf.lonestar.org
   
   
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

#include "cable_simulation_with_predefined_file.h"  // The include file for this module should come first.

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <stdint.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#include "errcodes.h"

#define debug(...) //fprintf(stderr, __VA_ARGS__ )

static bool was_rtl_cable_driver_initialised = false;
static jtag_cable_t rtl_cable_driver;

static const char *gdb_in  = "gdb_in.dat";
static const char *gdb_out = "gdb_out.dat";



/*-------------------------------------------[ rtl_sim specific functions ]---*/

static int cable_rtl_sim_init()
{
  FILE *fin = fopen (gdb_in, "wt+");
  if(!fin) {
    fprintf(stderr, "Can not open %s\n", gdb_in);
    return APP_ERR_INIT_FAILED;
  }
  fclose(fin);
  return APP_ERR_NONE;
}

static int cable_rtl_sim_out(uint8_t value)
{
  FILE *fout;
  int num_read;
  int r;
  debug("O (%x)\n", value);
  fout = fopen(gdb_in, "wt+");
  fprintf(fout, "F\n");
  fflush(fout);
  fclose(fout);
  fout = fopen(gdb_out, "wt+");
  fprintf(fout, "%02X\n", value);
  fflush(fout);
  fclose(fout);
  do {
    fout = fopen(gdb_out, "rt");
    r = fscanf(fout,"%x", &num_read);
    fclose(fout);
    usleep(1000);
    debug(" (Ack %x) ", num_read);
  } while(!r || (num_read != (0x10 | value)));
  debug("\n");
  return APP_ERR_NONE;
}

static int cable_rtl_sim_inout(uint8_t value, uint8_t *inval)
{
  FILE *fin = 0;
  char ch;
  uint8_t data;
  debug("IO (");

  while(1) {
    fin = fopen(gdb_in, "rt");
    if(!fin) {
      usleep(1000);
      continue;
    }
    ch = fgetc(fin);
    fclose(fin);
    if((ch != '0') && (ch != '1')) {
      usleep(1000);
      continue;
    }
    else
      break;
  }
  data = ch == '1' ? 1 : 0;

  debug("%x,", data);

  cable_rtl_sim_out(value);

  debug("%x)\n", value);

  *inval = data;
  return APP_ERR_NONE;
}


static int cable_rtl_sim_opt ( const int c, const char * const str )
{
  switch(c)
  {
  case 'd':
    {
      char *gdb_in_tmp;
      char *gdb_out_tmp;

      if(!(gdb_in_tmp = (char *)malloc(strlen(str) + 12))) /* 12 == strlen("gdb_in.dat") + 2 */
      {
        fprintf(stderr, "Unable to allocate enough memory\n");
        return APP_ERR_MALLOC;
      }
      if(!(gdb_out_tmp = (char *)malloc(strlen(str) + 13))) /* 13 == strlen("gdb_out.dat") + 2 */
      {
        fprintf(stderr, "Unable to allocate enough memory\n");
        free(gdb_in_tmp);
        return APP_ERR_MALLOC;
      }

      sprintf(gdb_in_tmp, "%s/gdb_in.dat", str);
      sprintf(gdb_out_tmp, "%s/gdb_out.dat", str);

      gdb_in  = gdb_in_tmp;
      gdb_out = gdb_out_tmp;

      break;
    }

  default:
    fprintf(stderr, "Unknown parameter '%c'\n", c);
    return APP_ERR_BAD_PARAM;
  }
  return APP_ERR_NONE;
}


jtag_cable_t * cable_rtl_get_driver ( void )
{
  if ( ! was_rtl_cable_driver_initialised )
  {    
    rtl_cable_driver.name ="rtl_sim";
    rtl_cable_driver.inout_func = cable_rtl_sim_inout;
    rtl_cable_driver.out_func = cable_rtl_sim_out;
    rtl_cable_driver.init_func = cable_rtl_sim_init;
    rtl_cable_driver.opt_func = cable_rtl_sim_opt;
    rtl_cable_driver.bit_out_func = cable_common_write_bit;
    rtl_cable_driver.bit_inout_func = cable_common_read_write_bit;
    rtl_cable_driver.stream_out_func = cable_common_write_stream;
    rtl_cable_driver.stream_inout_func = cable_common_read_stream;
    rtl_cable_driver.flush_func = NULL;
    rtl_cable_driver.opts = "d:";
    rtl_cable_driver.help = "\t-d [directory] Directory in which gdb_in.dat/gdb_out.dat may be found\n";

    was_rtl_cable_driver_initialised = true;
  }

  return &rtl_cable_driver; 
}
