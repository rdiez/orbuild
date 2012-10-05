/*
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

#include "cable_simulation_over_tcp_socket.h"  // The include file for this module should come first.

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <netdb.h>

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>
#include <stdint.h>
#include <assert.h>

#include <stdexcept>

#include "errcodes.h"
#include "string_utils.h"
#include "linux_utils.h"


#define debug(...) //fprintf(stderr, __VA_ARGS__ )

static bool was_vpi_cable_driver_initialised = false;
static jtag_cable_t vpi_cable_driver;

static int connection_socket = -1;
static int tcp_port = 4567;
static std::string remote_hostname = "localhost";


static int cable_vpi_init ( void )
{
  assert( connection_socket < 0 );

  connection_socket = socket( PF_INET, SOCK_STREAM, 0 );

  if ( connection_socket < 0 )
  {
    throw std::runtime_error( format_errno_msg( errno, "Cannot create TCP socket: " ) );
  }

  const hostent * const he = gethostbyname( remote_hostname.c_str() );

  if ( he == NULL )
  {
    throw std::runtime_error( format_msg( "Cannot resolve host name \"%s\".", remote_hostname.c_str() ) );
  }

  struct sockaddr_in addr;
  memset( &addr, 0, sizeof(addr) );
  addr.sin_family = AF_INET;
  addr.sin_port = htons(tcp_port);
  addr.sin_addr = *((struct in_addr *)he->h_addr);

  const std::string ip_addr_txt = ip_address_to_text( &addr.sin_addr );

  printf( "Connecting to simulated JTAG at %s (IP addr %s) on TCP port %d... ",
          remote_hostname.c_str(), ip_addr_txt.c_str(), tcp_port );

  const int connect_res = connect( connection_socket, (struct sockaddr *)&addr, sizeof(addr) );

  if ( connect_res != 0 )
  {
    const int saved_errno = errno;
    printf( "\n" );
    throw std::runtime_error( format_errno_msg( saved_errno, "Error connecting to simulated JTAG at %s (IP addr %s) on TCP port %d: ",
                                                remote_hostname.c_str(), ip_addr_txt.c_str(), tcp_port ) );
  }

  printf( "OK\n" );

  return APP_ERR_NONE;
}


static void send_one_byte ( const uint8_t data )
{
  assert( connection_socket != -1 );

  try
  {
    write_loop( connection_socket, &data, sizeof(data) );
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error writing to the JTAG socket: %s", e.what() ) );
  }
}


static uint8_t receive_one_byte ( void )
{
  assert( connection_socket != -1 );

  try
  {
    bool end_of_file;
    const uint8_t c = read_one_byte( connection_socket, &end_of_file );

    if ( end_of_file )
      throw std::runtime_error( "The remote server closed the connection." );

    return c;
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error reading from the JTAG socket: %s", e.what() ) );
  }
}


static void cable_vpi_wait ( void )
{
  // Get the sim to reply when the timeout has been reached.
  send_one_byte( 0x81 );

  // Block, waiting for the data.
  const uint8_t data_in = receive_one_byte();

  if(data_in != 0xFF)
    fprintf(stderr, "Warning: got wrong byte waiting for timeout: 0x%X\n", data_in);
}


static int cable_vpi_out ( const uint8_t value )
{
  send_one_byte( value );

  uint8_t ack;
  do
  {
    ack = receive_one_byte();

  } while(ack != (value | 0x10));

  cable_vpi_wait();  // finish the transaction

  return APP_ERR_NONE;
}


static int cable_vpi_inout ( const uint8_t value, uint8_t * const inval )
{
  // Ask the remote VPI/DPI server to send us the out-bit.
  send_one_byte( 0x80 );

  // Wait and read the data.
  const uint8_t data_in = receive_one_byte();

  if ( data_in > 1 )
    fprintf(stderr, "Unexpected value: %i\n", data_in );

  cable_vpi_out( value );

  *inval = data_in;

  // Finish the transaction.
  cable_vpi_wait();

  return APP_ERR_NONE;
}


static int cable_vpi_opt ( const int c, const char * const str )
{
  switch(c)
  {
  case 'p':
    tcp_port = atoi(str);

    if( tcp_port == 0 )
    {
      fprintf(stderr, "Bad port value for VPI cable: %s\n", str);
      return APP_ERR_BAD_PARAM;
    }
    break;
  case 's':
    remote_hostname = str;
    break;
  default:
    fprintf(stderr, "Unknown parameter '%c'\n", c);
    return APP_ERR_BAD_PARAM;
  }

  return APP_ERR_NONE;
}


static void cable_vpi_close ( void )
{
  if ( connection_socket != -1 )
    close_a( connection_socket );
}


jtag_cable_t * cable_vpi_get_driver ( void )
{
  if ( was_vpi_cable_driver_initialised )
  {
    // I think this routine gets called only once at the moment.
    assert( false );
  }
  else
  {
    vpi_cable_driver.name = "vpi";
    vpi_cable_driver.inout_func = cable_vpi_inout;
    vpi_cable_driver.out_func = cable_vpi_out;
    vpi_cable_driver.init_func = cable_vpi_init;
    vpi_cable_driver.opt_func = cable_vpi_opt;
    vpi_cable_driver.bit_out_func = cable_common_write_bit;
    vpi_cable_driver.bit_inout_func = cable_common_read_write_bit;
    vpi_cable_driver.stream_out_func = cable_common_write_stream;
    vpi_cable_driver.stream_inout_func = cable_common_read_stream;
    vpi_cable_driver.flush_func = NULL;
    vpi_cable_driver.close_func = cable_vpi_close;
    vpi_cable_driver.opts = "s:p:";
    vpi_cable_driver.help = "\t-s [server] Server name/address the remote JTAG VPI/DPI module is listening on\n"
                            "\t-p [port]   Port number that the remote JTAG VPI/DPI module is listening on\n";

    was_vpi_cable_driver_initialised = true;
  }

  return &vpi_cable_driver;
}
