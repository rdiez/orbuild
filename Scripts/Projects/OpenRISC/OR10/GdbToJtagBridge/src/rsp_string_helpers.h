
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

#ifndef RSP_STRING_HELPERS_H_INCLUDED
#define RSP_STRING_HELPERS_H_INCLUDED

#include <stdint.h>
#include <assert.h>

#include <stdexcept>

#include "string_utils.h"


uint32_t parse_reg_32_from_hex ( const char * buf );
void reg2hex ( uint32_t val, char * buf );

std::string ascii2hex ( const char * src );
std::string hex2ascii ( const char * src );


inline char get_hex_char ( const uint8_t value_0_to_15 )
{
  const char hexchars[] = "0123456789abcdef";

  assert( value_0_to_15 <= sizeof( hexchars ) - 1 );

  return hexchars[ value_0_to_15 ];
}


inline uint8_t parse_hex_digit ( const int c )
{
  switch ( c )
  {
  case '0':  return 0;
  case '1':  return 1;
  case '2':  return 2;
  case '3':  return 3;
  case '4':  return 4;
  case '5':  return 5;
  case '6':  return 6;
  case '7':  return 7;
  case '8':  return 8;
  case '9':  return 9;

  case 'a':  return 10;
  case 'b':  return 11;
  case 'c':  return 12;
  case 'd':  return 13;
  case 'e':  return 14;
  case 'f':  return 15;

  case 'A':  return 10;
  case 'B':  return 11;
  case 'C':  return 12;
  case 'D':  return 13;
  case 'E':  return 14;
  case 'F':  return 15;

  default:
    throw std::runtime_error( format_msg( "Illegal hex digit 0x%02X.", c ) );
  }
}


#endif	// Include this header file only once.
