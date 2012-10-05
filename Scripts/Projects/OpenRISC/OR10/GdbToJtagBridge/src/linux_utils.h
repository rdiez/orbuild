
#ifndef LINUX_UTILS_H_INCLUDED
#define LINUX_UTILS_H_INCLUDED

#include <errno.h>
#include <stdint.h>
#include <sys/socket.h>
#include <signal.h>
#include <dirent.h>
#include <usb.h>  // libusb header

void close_a ( int fd );
void closedir_a ( DIR * dirp);

void usb_close_a ( usb_dev_handle * dev );

inline int accept4_eintr ( const int sockfd,
                           struct sockaddr * const addr,
                           socklen_t * const addrlen,
                           const int flags )
{
  for ( ; ; )
  {
    const ssize_t ret = accept4( sockfd, addr, addrlen, flags );

    if ( ret == -1 && errno == EINTR )
      continue;

    return ret;
  }
}

void wait_ms ( int milliseconds );

typedef void (*signal_handler_func) ( int signo, siginfo_t * info, void * context );
void install_signal_handler ( int signal_number, signal_handler_func handler_func );

void setsockopt_e ( int socketFd,
                    int level,
                    int option_name,
                    const void * option_value,
                    socklen_t option_len );

void write_loop ( int fd, const void * buf, size_t byte_count );
uint8_t read_one_byte ( int fd, bool * end_of_file );

#endif  // Include this header only once.
