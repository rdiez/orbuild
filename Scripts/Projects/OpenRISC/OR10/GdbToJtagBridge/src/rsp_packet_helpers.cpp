
/* Copyright (C) 2008 Embecosm Limited
     Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
   Copyright (C) 2012 R. Diez

   This program is free software; you can redistribute it and/or modify it
   under the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3 of the License, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful, but WITHOUT
   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
   more details.

   You should have received a copy of the GNU General Public License along
   with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


#include "rsp_packet_helpers.h"  // The include file for this module should come first.

#include <netinet/tcp.h>  // For TCP_CORK.
#include <netinet/in.h>   // For IPPROTO_TCP.

#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

#include <stdexcept>

#include "rsp_string_helpers.h"
#include "string_utils.h"
#include "linux_utils.h"


bool enable_rsp_trace = false;

// POSSIBLE OPTIMISATION: Send the data in chunks instead of byte by byte.

static void put_rsp_char ( const int fd, const char c )
{
  assert( -1 != fd );

  try
  {
    write_loop( fd, &c, sizeof( c ) );
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error writing to the GDB client: %s", e.what() ) );
  }
}


// Reads a single character from the client socket.
//
// Returns -1 if the connection was closed gracefully by the remote client.
//
// POSSIBLE OPTIMISATION: Read the data in chunks instead of byte by byte.

static int get_rsp_char ( const int fd )
{
  assert( -1 != fd );

  try
  {
    bool end_of_file;
    const uint8_t c = read_one_byte( fd, &end_of_file );

    if ( end_of_file )
      return -1;
    else
      return c;
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error reading from the GDB client: %s", e.what() ) );
  }
}


/* Get a packet from the GDB client

   Unlike the reference implementation, we don't deal with sequence
   numbers. GDB has never used them, and this implementation is only intended
   for use with GDB 6.8 or later. Sequence numbers were removed from the RSP
   standard at GDB 5.0.

   Returns false if the connection was closed gracefully by the remote client.
*/

static bool get_packet_2 ( const int fd, const bool is_first_packet, rsp_buf * const buf )
{
  // Wait around for the start character ('$').

  for ( ; ; )
  {
    const int ch = get_rsp_char( fd );

    if ( -1 == ch )
    {
      return false;
    }

    if ( ch == '$' )
      break;

    if ( ch == GDB_RSP_BREAK_CMD )
    {
      buf->data[0] = ch;
      buf->len     = 1;
      return true;
    }

    // GDB seems to start sending "---+" characters at the beginning until the RSP server responds for the first time.
    if ( !is_first_packet || ( ch != '+' && ch != '-' ) )
      throw std::runtime_error( format_msg( "Invalid character 0x%02X received while looking for the start of next packet ('$').", ch ) );
  }


  // Read until a '#' is found.

  unsigned char checksum = 0;
  int count = 0;

  for ( ; ; )
  {
    if ( count >= GDB_BUF_MAX - 1 )
    {
      throw std::runtime_error( format_msg( "Buffer overflow reading the next packet." ) );
    }

    const int ch = get_rsp_char( fd );

    if ( '#' == ch )
    {
      break;
    }

    if ( -1 == ch )
    {
      throw std::runtime_error( "The remote end has closed the socket before writing a complete packet." );
    }

    if ( '$' == ch )
    {
      throw std::runtime_error( "Start of the next packet found while reading the previous packet." );
    }

    checksum         = checksum + (unsigned char)ch;
    buf->data[count] = (char)ch;
    count            = count + 1;
  }

  // Mark the end of the buffer with a null terminator, as it's convenient for non-binary data to be valid strings.
  assert( count < GDB_BUF_MAX );
  buf->data[count] = 0;
  buf->len         = count;

  // Validate the checksum.

  const int checksum1 = get_rsp_char( fd );
  if ( -1 == checksum1 )
  {
    throw std::runtime_error( "The remote end has closed the socket before writing a complete packet." );
  }

  const int checksum2 = get_rsp_char( fd );
  if ( -1 == checksum2 )
  {
    throw std::runtime_error( "The remote end has closed the socket before writing a complete packet." );
  }

  const unsigned char xmitcsum = ( parse_hex_digit( checksum1 ) << 4 ) +
                                   parse_hex_digit( checksum2 );

  if ( checksum == xmitcsum )
  {
    put_rsp_char( fd, '+' );   // Successful reception.
    return true;
  }

  throw std::runtime_error( format_msg( "Invalid packet checksum, computed 0x%02X, received 0x%02X\n",
                                        checksum, xmitcsum ) );
}


bool get_packet ( const int fd, const bool is_first_packet, rsp_buf * const buf )
{
  const bool res = get_packet_2( fd, is_first_packet, buf );

  if ( enable_rsp_trace && res )
  {
    printf( "GDB RSP packet received: %s\n", format_packet_for_tracing_purposes( buf ).c_str() );
  }

  return res;
}


// For more information about TCP_CORK, see this article:
//   "TCP_CORK: More than you ever wanted to know"
//   Christopher Baus
//   http://www.baus.net/on-tcp_cork

static void set_tcp_cork ( const int fd, const bool enable )
{
  const int opt_val = enable ? 1 : 0;

  setsockopt_e( fd,
                IPPROTO_TCP,  // We should probably use the value in rsp.proto_num.
                TCP_CORK,
                &opt_val,
                sizeof(opt_val) );
}


void put_packet ( const int fd, const rsp_buf * const buf )
{
  if ( enable_rsp_trace )
  {
    printf( "GDB RSP packet sent    : %s\n", format_packet_for_tracing_purposes( buf ).c_str() );
  }

  set_tcp_cork( fd, true );

  try
  {
    // Construct $<packet info>#<checksum>, escape characters as needed.

    put_rsp_char( fd, '$' );  // Start char.

    unsigned char checksum = 0;

    for ( int count = 0; count < buf->len; count++ )
    {
      unsigned char ch = buf->data[ count ];

      // Check for escaped chars.
      if (('$' == ch) || ('#' == ch) || ('*' == ch) || ('}' == ch))
      {
        checksum += (unsigned char)'}';
        put_rsp_char( fd, '}' );
        ch ^= 0x20;
      }

      checksum += ch;
      put_rsp_char( fd, ch );
    }

    put_rsp_char( fd, '#' );  // End char.

    // Send the computed checksum.
    put_rsp_char( fd, get_hex_char( checksum >> 4 ) );
    put_rsp_char( fd, get_hex_char( checksum % 16 ) );
  }
  catch ( ... )
  {
    set_tcp_cork( fd, false );
    throw;
  }
  set_tcp_cork( fd, false );

  const int ack_ch = get_rsp_char( fd );

  if ( ack_ch == '+' )
    return;

  if ( ack_ch == -1 )
  {
    throw std::runtime_error( "Error sending packet: Error reading the packet receipt confirmation: The GDB client has closed the connection." );
  }

  if ( ack_ch == '-' )
  {
    // GDB also sends a '-' on timeout. Depending on the error type, that might work fine on a serial line,
    // but when using a reliable connection like TCP, the old responses will just get delayed (and not discarded),
    // which cause further errors.
    throw std::runtime_error( "Error sending packet: The GDB client has requested a packet retransmission, which should never be "
                              "necessary when using a reliable connection like a TCP socket. "
                              "If this has been triggered by a communications timeout because the OR10/JTAG side needs more time, "
                              "try increasing the timeout limit with GDB's 'set remotetimeout' command." );
  }

  throw std::runtime_error( format_msg( "Error sending packet: The GDB client has sent an invalid packet receipt confirmation of 0x%02X.",
                                        ack_ch ) );
}


void put_str_packet ( const int fd, const std::string * str )
{
  if ( str->size() >= GDB_BUF_MAX - 1 )  // Leave place for an eventual null terminator.
  {
    assert( false );
    throw std::runtime_error( "Error sending packet: The packet contents are too big." );
  }

  rsp_buf buf;

  memcpy( buf.data, str->c_str(), str->size() );
  buf.len = int( str->size() );

  put_packet( fd, &buf );
}


void put_str_packet ( const int fd, const char * const str )
{
  const size_t len = strlen( str );

  if ( len >= GDB_BUF_MAX - 1 )  // Leave place for an eventual null terminator.
  {
    assert( false );
    throw std::runtime_error( "Error sending packet: The packet contents are too big." );
  }

  rsp_buf buf;

  memcpy( buf.data, str, len );
  buf.len = int( len );

  put_packet( fd, &buf );
}


void send_unknown_command_reply ( const int fd )
{
  // According to the GDB RSP specification, we must reply
  // with an empty packet whenever we receive a command we do not support.

  put_str_packet( fd, "" );
}


void send_ok_packet ( const int fd )
{
  put_str_packet( fd, "OK" );
}


std::string format_packet_for_tracing_purposes ( const rsp_buf * const buf )
{
  std::string ret;

  if ( buf->len == 0 )
  {
    ret = "<empty packet>";
  }
  else if ( buf->len == 1 && buf->data[0] == GDB_RSP_BREAK_CMD )
  {
    ret = "<break command>";
  }
  else
  {
    ret.push_back('"');

    for ( int i = 0; i < buf->len; ++i )
    {
      const char c = buf->data[i];

      if ( c >= 32 && c <= 127 )
      {
        ret.push_back( c );
      }
      else
      {
        ret.push_back( '!' );
      }
    }

    const char * const chars_txt = buf->len > 1 ? "chars" : "char";

    ret.append( format_msg( "\" (%d %s)", buf->len, chars_txt ) );
  }

  return ret;
}
