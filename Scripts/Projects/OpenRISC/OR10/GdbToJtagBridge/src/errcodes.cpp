/* errcodes.c - Error code to plaintext translator for the advanced JTAG bridge
   Copyright(C) 2008 - 2010 Nathan Yawn <nyawn@opencores.org>

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

#include "errcodes.h"  // The include file for this module should come first.

#include <assert.h>

#include <stdexcept>


std::string get_err_string ( const int err )
{
  std::string ret;

  if ( err & APP_ERR_COMM         )   ret.append( "\'JTAG comm error\' " );
  if ( err & APP_ERR_MALLOC       )   ret.append( "\'malloc failed\' ");
  if ( err & APP_ERR_MAX_RETRY    )   ret.append( "\'max retries\' ");
  if ( err & APP_ERR_CRC          )   ret.append( "\'CRC mismatch\' ");
  if ( err & APP_ERR_MAX_BUS_ERR  )   ret.append( "\'max WishBone bus errors\' ");
  if ( err & APP_ERR_CABLE_INVALID)   ret.append( "\'Invalid cable\' ");
  if ( err & APP_ERR_INIT_FAILED  )   ret.append( "\'init failed\' ");
  if ( err & APP_ERR_BAD_PARAM    )   ret.append( "\'bad command line parameter\' ");
  if ( err & APP_ERR_CONNECT      )   ret.append( "\'connection failed\' ");
  if ( err & APP_ERR_USB          )   ret.append( "\'USB\' ");
  if ( err & APP_ERR_CABLENOTFOUND)   ret.append( "\'cable not found\' ");

  if ( ret.empty() )
  {
    assert( false );
    ret = "<unknown error>";
  }

  return ret;
}


void throw_if_error ( const int err )
{
  if ( err == APP_ERR_NONE )
    return;

  throw std::runtime_error( get_err_string( err ) );
}
