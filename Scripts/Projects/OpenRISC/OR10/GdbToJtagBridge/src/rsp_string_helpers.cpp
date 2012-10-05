
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


#include "rsp_string_helpers.h"  // The include file for this module should come first.


// The supplied 8-digit hex string is converted to a 32-bit value according the target endianism.

uint32_t parse_reg_32_from_hex ( const char * const buf )
{
  uint32_t val;

  for ( int n = 0; n < 8; n++ )
  {
    #ifdef WORDSBIGENDIAN
      const int nyb_shift = n * 4;
    #else
      const int nyb_shift = 28 - (n * 4);
    #endif

    val |= parse_hex_digit( buf[n] ) << nyb_shift;
  }

  return val;
}


// The supplied 32-bit value is converted to an 8 digit hex string according
// the target endianism. It is null terminated for convenient printing,
// so the destination buffer must be 9 bytes long.

void reg2hex ( const uint32_t val, char * const buf )
{
  for ( int n = 0; n < 8; n++ )
  {
    #ifdef WORDSBIGENDIAN
      const int nyb_shift = n * 4;
    #else
      const int nyb_shift = 28 - (n * 4);
    #endif
      buf[n] = get_hex_char( (val >> nyb_shift) & 0xf );
  }

  buf[8] = 0;
}


/* Convert an ASCII character string to pairs of hex digits.

   Example: "A" -> "41", given that 'A' has the ASCII code of 0x41.

   Both source and destination are null terminated.

   The destination buffer must be big enough to contain
   twice as many characters as the source string has, plus the null terminator.
*/

std::string ascii2hex ( const char * const src )
{
  std::string ret;

  for ( unsigned i = 0; ; i++ )
  {
    const char ch = src[i];

    if ( ch == '\0' )
      break;

    ret.push_back( get_hex_char( ch >> 4  ) );
    ret.push_back( get_hex_char( ch & 0xf ) );
  }

  return ret;
}


// Convert pairs of hex digits to an ASCII character string, see ascii2hex() for more information.

std::string hex2ascii ( const char * const src )
{
  std::string ret;

  for ( unsigned i = 0; ; i++ )
  {
    if ( src[i * 2] == '\0' )
    {
      break;
    }

    if ( src[i * 2 + 1] == '\0' )
      throw std::runtime_error( "Error parsing an ASCII string from a hex string: the last hex digit pair is incomplete." );

    const char c = ( parse_hex_digit( src[i * 2    ] ) << 4  ) |
                     parse_hex_digit( src[i * 2 + 1] );

    ret.push_back( c );
  }

  return ret;
}
