
#include <linux_utils.h>  // Header file for this module should come first.

#include <unistd.h>

#include <errno.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include <stdexcept>

#include "string_utils.h"


void close_a ( const int fd )
{
  for ( ; ; )
  {
    const int res = close( fd );

    if ( res == -1 && errno == EINTR )
        continue;

    assert( res == 0 );

    break;
  }
}


void closedir_a ( DIR * const dirp )
{
  if ( 0 != closedir( dirp ) )
    assert( false );
}


void usb_close_a ( usb_dev_handle * const dev )
{
    if ( 0 != usb_close( dev ) )
        assert( false );
}


void wait_ms ( const int milliseconds )
{
    timespec req, rem;

    req.tv_sec = milliseconds / 1000;
    req.tv_nsec = ( milliseconds % 1000 ) * 1000000;

    for ( ; ; )
    {
        const int res = nanosleep( &req, &rem );

        if ( res == 0 )
            return;

        const int errno_code = errno;

        if ( errno_code != EINTR )
        {
          throw std::runtime_error( format_errno_msg( errno_code, "Error sleeping: " ) );
        }

        req = rem;
    }
}


void install_signal_handler ( const int signal_number, const signal_handler_func handler_func )
{
    try
    {
        struct sigaction act;

        act.sa_sigaction = handler_func;
        act.sa_flags     = SA_SIGINFO | SA_RESTART;

        if ( 0 != sigemptyset( &act.sa_mask ) )
            throw std::runtime_error( "Error setting signal mask." );

        if ( 0 != sigaction( signal_number, &act, NULL ) )
            throw std::runtime_error( format_errno_msg( errno, "Error setting signal handler: " ) );

        if ( 0 != siginterrupt( signal_number, 0 ) )
            throw std::runtime_error( format_errno_msg( errno, "Error setting signal interrupt: " ) );
    }
    catch ( const std::exception & e )
    {
        throw std::runtime_error( format_msg( "Error installing signal handler for signal %d: \"%s\": ", signal_number, e.what() ) );
    }
}


void setsockopt_e ( int socketFd,
                    int level,
                    int option_name,
                    const void * option_value,
                    socklen_t option_len )
{
    if ( 0 != setsockopt( socketFd, level, option_name, option_value, option_len ) )
        throw std::runtime_error( format_errno_msg( errno, "Error setting socket option: " ) );
}


// Calls write() as many times as necessary to write all the data. Retries if interrupted by a signal.
// Throws an exception on error.

void write_loop ( const int fd, const void * const buf, const size_t byte_count )
{
    const uint8_t * curr_pos = (const uint8_t *) buf;
    size_t byte_count_left = byte_count;

    while ( byte_count_left > 0 )
    {
        const ssize_t written_count = write( fd, curr_pos, byte_count_left );

        if ( -1 == written_count )
        {
            const int errno_code = errno;

            if ( errno_code == EINTR || errno_code == EAGAIN )
                continue;

            throw std::runtime_error( format_errno_msg( errno_code, "Error writing to file descriptor: " ) );
        }

        if ( written_count <= 0 )
        {
            assert( false );  // Should never happen.
            throw std::runtime_error( "Error writing to file descriptor." );
        }

        assert( size_t(written_count) <= byte_count_left );

        byte_count_left -= written_count;
        curr_pos += written_count;
    }
}


// Reads a single byte. Retries if interrupted by a signal. Throws an exception on error.

uint8_t read_one_byte ( const int fd, bool * const end_of_file )
{
    *end_of_file = false;

    for ( ; ; )
    {
        uint8_t c;
        const int read_byte_count = read( fd, &c, sizeof (c) );

        switch ( read_byte_count )
        {
        case -1:
          {
            const int errno_code = errno;

            if ( (EAGAIN != errno_code) && (EINTR != errno_code) )
            {
                throw std::runtime_error( format_errno_msg( errno_code, NULL ) );
            }

            break;
          }

        case 0:
            // The remote end has closed the connection gracefully.
            *end_of_file = true;
            return 0;

        case 1:
            return c;

        default:
            assert( false );  // Should never happen.
            throw std::runtime_error( format_msg( "Unexpected read length of %d bytes.", read_byte_count ) );
        }
    }
}
