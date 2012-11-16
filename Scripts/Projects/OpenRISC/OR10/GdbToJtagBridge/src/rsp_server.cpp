/* Remote Serial Protocol server for GDB

   The protocol used for communication is specified in OR1KSIM_RSP_PROTOCOL.

   Copyright (C) 2008 Embecosm Limited
     Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
   Copyright (C) 2008-2010 Nathan Yawn <nyawn@opencores.net>
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

#include "rsp_server.h"  // The include file for this module should come first.

#include <stdlib.h>
#include <unistd.h>
#include <netdb.h>
#include <stdio.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <arpa/inet.h>
#include <poll.h>
#include <netinet/tcp.h>
#include <string.h>
#include <netinet/in.h>
#include <assert.h>

#include <stdexcept>

#include "rsp_or10.h"
#include "string_utils.h"
#include "linux_utils.h"
#include "rsp_packet_helpers.h"

// Name of the RSP service, used to look the port number up in the operating system's
// config files (usually "/etc/services") if no port number was specified by the user.
#define OR1KSIM_RSP_SERVICE  "jtag-rsp"

// Protocol used by or1ksim.
#define OR1KSIM_RSP_PROTOCOL  "tcp"

rsp_struct rsp;


// Close the server if it is open.

static void rsp_close_listening_server_socket ( void )
{
  if ( -1 != rsp.server_fd )
  {
    close_a( rsp.server_fd );
    rsp.server_fd = -1;
  }
}


// Close the client if it is open.

static void rsp_client_close ( void )
{
  assert( -1 != rsp.client_fd );
  close_a( rsp.client_fd );
  rsp.client_fd = -1;
}


/* Initialize the Remote Serial Protocol connection

   This involves setting up a socket to listen on a socket for attempted
   connections from a single GDB instance (we couldn't be talking to multiple
   GDBs at once!).
*/

static void setup_listening_socket ( const int port_number_arg, const bool listen_on_local_addr_only )
{
  assert( rsp.server_fd == -1 );
  assert( rsp.client_fd == -1 );

  // An RSP port number of 0 indicates that we should look up the port number
  // based on the service name instead. The look-up table is usually in file "/etc/services".
  int portNum;

  if ( 0 == port_number_arg )
  {
      const servent * const service = getservbyname( OR1KSIM_RSP_SERVICE, OR1KSIM_RSP_PROTOCOL );

      if ( NULL == service )
      {
        // getservbyname() does not seem to be setting errno.
        throw std::runtime_error( format_msg( "Unable to find the port number for network service name \"%s\": ",
                                              OR1KSIM_RSP_SERVICE ) );
      }

      portNum = ntohs( service->s_port );
  }
  else
    portNum = port_number_arg;


  const int listening_socket_fd = socket( PF_INET, SOCK_STREAM, rsp.proto_num );

  if ( listening_socket_fd < 0 )
  {
    throw std::runtime_error( format_errno_msg( errno, "Cannot create the listening socket: " ) );
  }

  // From this point on, rsp_close_listening_server_socket() will close the socket.
  rsp.server_fd = listening_socket_fd;


  // If this process terminates abruptly, the TCP/IP stack does not release
  // the listening ports immediately, at least under Linux (I've seen comments
  // about this issue under Windows too). Therefore, if you restart this program
  // whithin a few seconds, you'll get an annoying "address already in use" error message.
  // The SO_REUSEADDR flag prevents this from happening.
  const int optval = 1;
  if ( setsockopt( rsp.server_fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof (optval) ) < 0 )
  {
    throw std::runtime_error( format_errno_msg( errno, "Cannot set the SO_REUSEADDR option on the server socket: " ) );
  }


  // Bind our socket to the appropriate address and port.
  sockaddr_in sock_addr;
  memset( &sock_addr, 0, sizeof(sock_addr) );
  sock_addr.sin_family      = AF_INET;
  sock_addr.sin_port        = htons( portNum );
  sock_addr.sin_addr.s_addr = ntohl( listen_on_local_addr_only ? INADDR_LOOPBACK : INADDR_ANY );

  if ( bind( rsp.server_fd,
             (struct sockaddr *)&sock_addr,
             sizeof (sock_addr) ) < 0)
  {
    throw std::runtime_error( format_errno_msg( errno, "Cannot bind the server socket to TCP port %d: ", portNum ) );
  }


  // Mark us as a listening port, with a maximum backlog of 1 connection, as we
  // will never connect simultaneously to more than one RSP client.
  const int backlog_count = 1;
  if ( listen( rsp.server_fd, backlog_count ) < 0 )
  {
    throw std::runtime_error( format_errno_msg( errno, "Cannot set the server socket backlog to %d: ", backlog_count ) );
  }


  const std::string ip_addr_txt = ip_address_to_text( &sock_addr.sin_addr );

  printf( "The GDB RSP server is listening on IP address %s (%s), TCP port %d.\n",
          ip_addr_txt.c_str(),
          listen_on_local_addr_only ? "localhost loopback only" : "all IP addresses",
          portNum );
}


static void accept_incoming_gdb_client_connection ( void )
{
  assert( -1 == rsp.client_fd );

  sockaddr_in sock_addr;
  socklen_t sock_addr_len = sizeof( sock_addr );

  // Do not specify flag SOCK_NONBLOCK. Our server is not asynchronous and cannot deal
  // with EWOULDBLOCK errors.
  rsp.client_fd = accept4_eintr( rsp.server_fd,
                                 (struct sockaddr *)&sock_addr,
                                 &sock_addr_len,
                                 SOCK_CLOEXEC );
  if ( rsp.client_fd == -1 )
  {
    throw std::runtime_error( format_errno_msg( errno, "Error accepting a client connection: " ) );
  }

  rsp.is_first_packet = true;

  const std::string addr_str = ip_address_to_text( &sock_addr.sin_addr );

  printf( "Accepted an incoming connection from IP address %s, TCP port %d.\n",
          addr_str.c_str(),
          ntohs( sock_addr.sin_port ) );

  // Turn off Nagel's algorithm for the client socket, see "Nagle's algorithm" in Wikipedia for more information.
  /* I'm not sure that this is a good idea, I'm using TCP_CORK later on instead.
  const int opt_val = 0;
  setsockopt_e( rsp.client_fd,
                rsp.proto_num,
                TCP_NODELAY,
                &opt_val,
                sizeof(opt_val) );
  */
}


static void wait_for_client_connection ( const int port_number,
                                         const bool listen_on_local_addr_only,
                                         const bool * const exit_request )
{
  // If no RSP client (which is normally GDB) has connected yet, poll the server (listening) socket until
  // a client initiates a connection.

  assert( -1 == rsp.client_fd );

  if ( -1 == rsp.server_fd )
    setup_listening_socket( port_number, listen_on_local_addr_only );

  for ( ; ; )
  {
    pollfd fds[1];
    fds[0].fd     = rsp.server_fd;
    fds[0].events = POLLIN;

    const int POLL_TIMEOUT = 1000;
    const int poll_res = poll( fds, 1, POLL_TIMEOUT );

    switch ( poll_res )
    {
    case -1:
      if ( *exit_request )
        return;

      if ( EINTR != errno )
      {
        throw std::runtime_error( format_errno_msg( errno, "Error polling the RSP listening server socket: " ) );
      }
      break;

    case 0:
      // // Timeout, this should not happen.
      // assert( false );
      // throw std::runtime_error( "Error polling the RSP listening server socket: Unexpected timeout." );

      // Every now and then send a request. Otherwise, we may not realise for a long time when the connection is lost.
      check_connection_with_cpu_is_still_there();
      break;

    case 1:
      if ( POLLIN == ( fds[0].revents & POLLIN ) )
      {
        accept_incoming_gdb_client_connection();
        rsp_close_listening_server_socket();
        attach_to_cpu();
        return;
      }

      throw std::runtime_error( format_msg( "Error polling the RSP listening server socket: Unexpected socket event flags 0x%08X.",
                                              fds[0].revents ) );
    default:
      throw std::runtime_error( format_msg( "Error polling the RSP listening server socket: Unexpected poll() result of %d.",
                                            poll_res ) );
    }
  }
}


void process_rsp_client_request ( void )
{
  // Any errors reading o processing a packet close the client connection.

  rsp_buf buf;

  bool packet_received_ok = false;

  try
  {
    if ( ! get_packet( rsp.client_fd, rsp.is_first_packet, &buf ) )
    {
      printf( "The remote GDB client closed the connection.\n" );
      detach_from_cpu();
      rsp_client_close();
      return;
    }

    packet_received_ok = true;
    rsp.is_first_packet = false;

    process_client_command( &buf );
  }
  catch ( const std::exception & e )
  {
    if ( packet_received_ok )
    {
      fprintf( stderr,
               "Error processing a GDB packet: %s - The packet was: %s\n",
               e.what(), format_packet_for_tracing_purposes( &buf ).c_str() );
    }
    else
    {
      fprintf( stderr, "Error reading a packet from the remote GDB client: %s\n", e.what() );
    }

    fprintf( stderr, "The connection with the GDB client has been closed after receiving the error above.\n" );
    detach_from_cpu();
    rsp_client_close();
  }
}


static void wait_for_next_client_request ( const bool * const exit_request )
{
  assert( -1 != rsp.client_fd );

  // Poll the RSP client socket for a message from GDB.

  pollfd fds[1];

  fds[0].fd     = rsp.client_fd;
  fds[0].events = POLLIN;


  // There are 3 reasons why there is a time-out here:
  // 1) Regularly polling the CPU status will make as notice if the JTAG connection
  //    has stopped working.
  // 2) When the CPU is running, we should be able to realise when it has stalled again.
  // Note that exit requests are not affected, see comment about signals and EINTR below.

  int poll_timeout;

  switch ( rsp.cpu_poll_speed )
  {
  case CPS_FAST:
    poll_timeout = 100;  // This impacts the debugger's response time when single-stepping.
    break;

  case CPS_MIDDLE:
    poll_timeout = 300;  // This impacts the debugger's response time when the CPU hits a breakpoint.
    break;

  default:
    assert( false );
    // Fall through.

  case CPS_SLOW:
    poll_timeout = 1000;  // This does NOT limit the reaction time to an exit request,
                          // as the reception of signals will interrupt the poll() call (see EINTR below).
    break;
  }

  const int poll_res = poll( fds, 1, poll_timeout );

  switch ( poll_res )
  {
  case -1:
    if ( *exit_request )
      break;

    if ( EINTR != errno )
    {
      throw std::runtime_error( format_errno_msg( errno, "Error polling the RSP client connection socket: " ) );
    }
    break;

  case 0:
    poll_cpu();
    break;

  case 1:
    {
      // Is the client activity due to input available?
      if ( POLLIN == ( fds[0].revents & POLLIN ) )
      {
        process_rsp_client_request();
        break;
      }

      throw std::runtime_error( format_msg( "Error polling the RSP client connection socket: Unexpected socket event flags 0x%08X.",
                                            fds[0].revents ) );
    }

  default:
    throw std::runtime_error( format_msg( "Error polling the RSP client connection socket: Unexpected poll() result of %d.",
                                          poll_res ) );
  }
}


static void shutdown ( void )
{
  if ( -1 != rsp.client_fd )
      rsp_client_close();

  rsp_close_listening_server_socket();
}


void handle_rsp ( const int port_number,
                  const bool listen_on_local_addr_only,
                  const bool trace_rsp,
                  const bool trace_jtag,
                  const bool * const exit_request )
{
  try
  {
    // This handles requests from GDB. I'd prefer the while() loop to be in the function
    // with the select()/poll(), but the or1ksim rsp code (ported for use here) doesn't work
    // that way, and I don't want to rework that code (to make it easier to import fixes
    // written for the or1ksim rsp server).  --NAY
    //
    // Comment from rdiez: The whole bridge program should be rewritten in order to
    // handle all socket traffic asynchronously. The socket connections are:
    //   1) GDB RSP
    //   2) JTAG Serial Port
    //   3) cable_simulation_over_tcp_socket
    // The current synchronous implementation has the usual weaknesses: if a socket stalls,
    // all other traffic is affected. If any of the 3 possible connections is lost, the code
    // may not realise if it's waiting on another socket.

    enable_rsp_trace = trace_rsp;
    enable_or10_jtag_trace( trace_jtag );

    rsp.server_fd = -1;
    rsp.client_fd = -1;

    // Get the protocol number for TCP and save it for future use.
    const protoent * const protocol = getprotobyname( OR1KSIM_RSP_PROTOCOL );

    if ( NULL == protocol )
    {
      // Note that getprotobyname() does not set errno.
      throw std::runtime_error( format_msg( "Unable to load protocol \"%s\".",
                                            OR1KSIM_RSP_PROTOCOL ) );
    }

    rsp.proto_num = protocol->p_proto;    // Saved for future client use


    // Server loop.

    for ( ; ; )
    {
      if ( -1 == rsp.client_fd )
        wait_for_client_connection( port_number, listen_on_local_addr_only, exit_request );

      if ( *exit_request )
        break;

      wait_for_next_client_request( exit_request );

      if ( *exit_request )
        break;
    }
  }
  catch ( ... )
  {
    // Trying to detach from the CPU here may cause further errors if the JTAG connection has been lost.
    //  detach_from_cpu();
    shutdown();
    throw;
  }

  if ( -1 != rsp.client_fd )
    detach_from_cpu();

  shutdown();
}
