
#include <string_utils.h>  // Header file for this module should come first.

#include <arpa/inet.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <assert.h>
#include <errno.h>

#include <stdexcept>


static std::string format_msg_v ( const char * format_str, va_list arg_list )
{
    std::string ret;

    char * str;
    const int res = vasprintf( &str, format_str, arg_list );

    if ( -1 == res )
      throw std::bad_alloc();

    try
    {
      ret = str;
    }
    catch ( ... )
    {
      free( str );
      throw;
    }

    free( str );
    return ret;
}


std::string format_msg ( const char * format_str, ... )
{
    va_list arg_list;
    va_start( arg_list, format_str );

    const std::string ret = format_msg_v( format_str, arg_list );

    va_end( arg_list );

    return ret;
}


std::string format_errno_msg ( const int errno_val,
                               const char * const prefix_msg_fmt,  // Can be NULL.
                               ... )
{
  va_list arg_list;
  va_start( arg_list, prefix_msg_fmt );

  std::string prefix_msg;

  if ( prefix_msg_fmt != NULL )
    prefix_msg = format_msg_v( prefix_msg_fmt, arg_list );

  va_end( arg_list );


  char buffer[ 2048 ];

  #if (_POSIX_C_SOURCE >= 200112L || _XOPEN_SOURCE >= 600) && ! _GNU_SOURCE
  #error "The call to strerror_r() below will not compile properly. The easiest thing to do is to define _GNU_SOURCE when compiling this module."
  #endif

  const char * const strerror_msg = strerror_r( errno_val, buffer, sizeof(buffer) );

  std::string sys_msg;

  if ( strerror_msg == NULL )
  {
    sys_msg = "<no error message available>";
  }
  else
  {
    // According to the strerror_r() documentation, if the string lands in the buffer,
    // it may be truncated, but it always includes a terminating null byte.
    sys_msg = strerror_msg;
  }

  const std::string ret = format_msg( "%sError code %d: %s",
                                      prefix_msg.c_str(),
                                      errno_val,
                                      sys_msg.c_str() );
  return ret;
}


std::string ip_address_to_text ( const in_addr * const addr )
{
  char ip_addr_buffer[80];

  const char * const str = inet_ntop( AF_INET,
                                      addr,
                                      ip_addr_buffer,
                                      sizeof(ip_addr_buffer) );
  if ( str == NULL )
  {
    throw std::runtime_error( format_errno_msg( errno, "Error formatting the IP address: " ) );
  }

  assert( strlen(str) <= strlen("123.123.123.123") );
  assert( strlen(str) <= sizeof(ip_addr_buffer) );

  return str;
}


bool str_starts_with ( const std::string * const str,
                       const std::string * const prefix )
{
  if ( str->size() < prefix->size() )
    return false;

  for ( std::string::size_type i = 0; i < prefix->size(); ++i )
  {
    if ( (*str)[i] != (*prefix)[i] )
      return false;
  }

  return true;
}


bool str_remove_prefix ( std::string * const str,
                         const std::string * const prefix )
{
  if ( str_starts_with( str, prefix ) )
  {
    str->erase( 0, prefix->size() );
    return true;
  }
  else
  {
    return false;
  }
}
