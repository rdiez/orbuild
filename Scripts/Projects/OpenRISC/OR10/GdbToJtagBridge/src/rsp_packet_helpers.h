
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

#ifndef RSP_PACKET_HELPERS_H_INCLUDED
#define RSP_PACKET_HELPERS_H_INCLUDED

#include <string>

// 0x03 is a special case, an out-of-band break command when the target is running.
#define GDB_RSP_BREAK_CMD 0x03

// The maximum number of characters in inbound/outbound buffers.
// The max is 16kB, and larger buffers make for faster
// transfer times, so use the max. If your setup is prone
// to JTAG communication errors, you may want to use a smaller size.
//
// There is one extra byte at the end for an eventual string null terminator.
#define GDB_BUF_MAX  (16*1024 + 1)  // ((NUM_REGS) * 8 + 1)


// Data structure for RSP buffers. The data cannot be a null-terminated string,
// since it may include zero bytes.
struct rsp_buf
{
  char  data[GDB_BUF_MAX];
  int   len;
};


bool get_packet ( int fd, bool is_first_packet, rsp_buf * buf );
void put_packet ( int fd, const rsp_buf * buf );
void put_str_packet ( int fd, const char * str );
void put_str_packet ( int fd, const std::string * str );
void send_unknown_command_reply ( int fd );
void send_ok_packet ( int fd );
std::string format_packet_for_tracing_purposes ( const rsp_buf * buf );

#endif	// Include this header file only once.
