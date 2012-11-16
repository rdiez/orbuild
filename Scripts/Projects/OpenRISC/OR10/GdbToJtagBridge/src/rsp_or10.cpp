/*
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

#include "rsp_or10.h"  // The include file for this module should come first.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

#include <stdexcept>

#include "rsp_or10.h"
#include "spr-defs.h"
#include "dbg_api.h"
#include "string_utils.h"
#include "linux_utils.h"
#include "rsp_string_helpers.h"
#include "rsp_packet_helpers.h"


// Indices of GDB registers that are not GPRs. Must match GDB settings.
#define PPC_REGNUM  (MAX_GPRS + 0)  // Previous PC
#define NPC_REGNUM  (MAX_GPRS + 1)  // Next PC
#define SR_REGNUM   (MAX_GPRS + 2)  // Supervision Register
#define NUM_REGS    (MAX_GRPS + 3)  // Total GDB registers

// Opcode for the ORBIS32 "l.trap 1" instruction, used to plant breakpoints.
#define OR1K_TRAP_INSTR  ( 0x21000000 | (1<<15) )  // Bit 15 of the SPR SR should always be 1, so this l.trap instruction
                                                   // should always trigger the debugger.

// Definition of GDB target signals. Data taken from the GDB 6.8 source.
// Only those we use are defined here.
enum target_signal
{
  TARGET_SIGNAL_NONE =  0,
  TARGET_SIGNAL_INT  =  2,
  TARGET_SIGNAL_ILL  =  4,
  TARGET_SIGNAL_TRAP =  5,  // The only one used at the moment.
  TARGET_SIGNAL_FPE  =  8,
  TARGET_SIGNAL_BUS  = 10,
  TARGET_SIGNAL_SEGV = 11,
  TARGET_SIGNAL_ALRM = 14,
  TARGET_SIGNAL_USR2 = 31,
  TARGET_SIGNAL_PWR  = 32
};


// Scratch buffer, reused for performance.
std::string s_scratch;

#define STD_ERROR_CODE "E01"  // The one and only error code we return to GDB.


static void unstall_cpu ( void )
{
  assert( !rsp.is_target_running );
  dbg_cpu0_write_spr_e( SPR_DU_EDIS, 0 );
  rsp.is_target_running = true;
}

static void stall_cpu ( void )
{
  dbg_cpu0_write_spr_e( SPR_DU_EDIS, 1 );
  rsp.is_target_running = false;
}


static void collect_cpu_stop_reason ( const bool stopped_via_edis )
{
  assert( rsp.is_target_running == false );

  uint32_t drrval;
  dbg_cpu0_read_spr_e( SPR_DRR, &drrval );  // Read the DRR, find out why the CPU stopped.

  // Note that the current OR10 implementation only supports the "trap" reason.
  assert( drrval == 0 || drrval == SPR_DRR_TE );

  int sigval;  // GDB signal equivalent to exception

  switch ( drrval )
  {
    case SPR_DRR_RSTE:   sigval  = TARGET_SIGNAL_PWR;  break;
    case SPR_DRR_BUSEE:  sigval  = TARGET_SIGNAL_BUS;  break;
    case SPR_DRR_DPFE:   sigval  = TARGET_SIGNAL_SEGV; break;
    case SPR_DRR_IPFE:   sigval  = TARGET_SIGNAL_SEGV; break;
    case SPR_DRR_TTE:    sigval  = TARGET_SIGNAL_ALRM; break;
    case SPR_DRR_AE:     sigval  = TARGET_SIGNAL_BUS;  break;
    case SPR_DRR_IIE:    sigval  = TARGET_SIGNAL_ILL;  break;
    case SPR_DRR_IE:     sigval  = TARGET_SIGNAL_INT;  break;
    case SPR_DRR_DME:    sigval  = TARGET_SIGNAL_SEGV; break;
    case SPR_DRR_IME:    sigval  = TARGET_SIGNAL_SEGV; break;
    case SPR_DRR_RE:     sigval  = TARGET_SIGNAL_FPE;  break;
    case SPR_DRR_SCE:    sigval  = TARGET_SIGNAL_USR2; break;
    case SPR_DRR_FPE:    sigval  = TARGET_SIGNAL_FPE;  break;
    case SPR_DRR_TE:     sigval  = TARGET_SIGNAL_TRAP; break;

    // In the current OR10 hardware implementation, a single-step does not raise a TRAP,
    // so the DRR reads back 0. GDB expects a TRAP signal, so convert it here.
    // If the CPU was not in single-step mode, we have lost the last stop reason,
    // a TRAP should be alright too.
    case 0:
      assert( rsp.is_in_single_step_mode || stopped_via_edis );
      sigval = TARGET_SIGNAL_TRAP;
      break;

    default:
      assert( false );  // Should actually never happen.
      throw std::runtime_error( format_msg( "The CPU SPR DDR register contains the illegal value 0x%08X.", drrval ) );
  }

  rsp.sigval = sigval;
}


static void set_single_step_mode ( const bool enable )
{
  uint32_t dmr1;
  dbg_cpu0_read_spr_e( SPR_DMR1, &dmr1 );

  if ( enable )
    dmr1 |= SPR_DMR1_ST;
  else
    dmr1 &= ~SPR_DMR1_ST;

  dbg_cpu0_write_spr_e( SPR_DMR1, dmr1 );

  rsp.is_in_single_step_mode = enable;
}


void attach_to_cpu ( void )
{
  // Stall the CPU before doing anything else. Otherwise, there would be a window of opportunity
  // for the software to modify the same SPR registers being accessed here.
  stall_cpu();

  // Set up the CPU to break to the Debug Unit on exceptions.
  // Note that the current OR10 implementation only supports breaking on the l.trap instruction (TRAP exception).
  dbg_cpu0_write_spr_e( SPR_DSR, SPR_DSR_TE );

  // Just in case the single-step mode was activated, reset it.
  set_single_step_mode( false );

  collect_cpu_stop_reason( true );

  // Leave the CPU stalled. This is what GDB expects upon connecting.

  rsp.cpu_poll_speed = CPS_SLOW;
}


void detach_from_cpu ( void )
{
  // If target is running, stop it so we can modify SPRs without the software interfering.

  if ( rsp.is_target_running )
  {
    dbg_cpu0_write_spr_e( SPR_DU_EDIS, 1 );
    rsp.is_target_running = false;
  }

  // Clear the DSR: Don't transfer control to the Debug Unit for any reason.
  dbg_cpu0_write_spr_e( SPR_DSR, 0 );

  set_single_step_mode( false );

  // Leave the CPU running, otherwise it will forever remain stalled.
  unstall_cpu();
}


static void kill_request ( void )
{
  // Kill request. Do nothing for now.
}


static void send_signal_reply_packet ( void )
{
  // In GDB jargon exceptions are called "signals" and have an associated signal ID.
  rsp_buf buf;

  buf.data[0] = 'S';
  buf.data[1] = get_hex_char( rsp.sigval >> 4 );
  buf.data[2] = get_hex_char( rsp.sigval % 16 );
  buf.data[3] = 0;
  buf.len     = strlen (buf.data);

  put_packet( rsp.client_fd, &buf );
}


/* Generic processing of a continue request

   The signal may be EXCEPT_NONE if there is no exception to be
   handled. Currently the exception is ignored.

   The single step flag is cleared in the debug registers and then the
   processor is unstalled.
*/

static void rsp_continue_generic ( const unsigned long int except )
{
  // Clear Debug Reason Register, which holds the reason why the CPU stalled the last time.
  dbg_cpu0_write_spr_e( SPR_DRR, 0 );

  if ( rsp.is_in_single_step_mode )
  {
    set_single_step_mode( false );
  }

  unstall_cpu();
  rsp.cpu_poll_speed = CPS_MIDDLE;
}


/* Handle an RSP continue request

   Parse the command to see if there is an address. Uses the underlying
   generic continue function, with EXCEPT_NONE.
*/

static void rsp_continue ( const rsp_buf * const buf )
{
  assert( buf->data[0] == 'c' );

  if ( buf->len != 1 )
  {
    unsigned long int addr;

    if ( 1 != sscanf( buf->data, "c%lx", &addr ) )
    {
      throw std::runtime_error( "Illegal address to continue from." );
    }

    throw std::runtime_error( "The 'continue' command with a given address is not supported yet." );
  }

  rsp_continue_generic( EXCEPT_NONE );
}


/* The registers follow the GDB sequence for OR1K:
     - GPR0 through GPR31
     - PPC (i.e. SPR PPC)
     - NPC (i.e. SPR NPC)
     - SR (i.e. SPR SR).

   Each register is returned as a sequence of bytes in target endian order.

   Each byte is packed as a pair of hex digits.
*/

static void rsp_read_all_regs ( void )
{
  rsp_buf      buf;
  uint32_t     regbuf[MAX_GPRS];

  for ( int i = 0; i < MAX_GPRS; ++i )
  {
    dbg_cpu0_read_spr_e( SPR_GPR_BASE + i, &regbuf[i] );
    reg2hex( regbuf[i], &(buf.data[i * 8]) );
  }

  dbg_cpu0_read_spr_e( SPR_NPC, &regbuf[0] );
  dbg_cpu0_read_spr_e( SPR_SR , &regbuf[1] );
  // dbg_cpu0_read_spr_e( SPR_PPC, &regbuf[2] );  // The PPC register is not supported by the OR10 CPU.
  regbuf[2] = 0;

  // Note that reg2hex adds a NULL terminator; as such, they must be
  // put in buf.data in numerical order:  PPC, NPC, SR
  reg2hex( regbuf[2], &(buf.data[PPC_REGNUM * 8]) );
  reg2hex (regbuf[0], &(buf.data[NPC_REGNUM * 8]) );
  reg2hex (regbuf[1], &(buf.data[SR_REGNUM  * 8]) );

  //fprintf(stderr, "Read SPRs:  0x%08X, 0x%08X, 0x%08X\n", regbuf[0], regbuf[1], regbuf[2]);

  // Finalize the packet and send it.
  buf.data[NUM_REGS * 8] = 0;
  buf.len                = NUM_REGS * 8;
  put_packet( rsp.client_fd, &buf );
}


/* Handle a RSP read memory (symbolic) request

   Syntax is:

     m<addr>,<length>:

   The response is the bytes, lowest address first, encoded as pairs of hex digits.

   The length given is the number of bytes to be read.
*/

static void rsp_read_mem ( const rsp_buf * const buf )
{
  unsigned int addr;
  unsigned int len;

  assert( buf->data[0] == 'm' );

  if ( 2 != sscanf( buf->data, "m%x,%x:", &addr, &len ) || len <= 0 )
  {
    throw std::runtime_error( "Illegal read memory packet." );
  }

  // Make sure we won't overflow the buffer (2 chars per byte).
  if ( len * 2 >= GDB_BUF_MAX )
  {
    throw std::runtime_error( "The read memory packet's reponse would overflow the packet buffer." );
  }

  std::vector< uint8_t > data;
  dbg_cpu0_read_mem( uint32_t( addr ), uint32_t( len ), &data );

  const unsigned actually_read_len = data.size();
  rsp_buf reply;

  for ( unsigned off = 0; off < actually_read_len; off++ )
  {
    const unsigned char ch = data[ off ];
    // printf( "Memory read, byte at %u: 0x%02X\n", off, ch );
    reply.data[off * 2]     = get_hex_char( ch >>   4 );
    reply.data[off * 2 + 1] = get_hex_char( ch &  0xf );
  }

  reply.data[actually_read_len * 2] = 0;  // End of string.
  reply.len = actually_read_len * 2;
  put_packet( rsp.client_fd, &reply );
}


/* Handle a RSP write memory (symbolic) request

   Syntax is:

     M<addr>,<length>:<data>

   The data is the bytes, lowest address first, encoded as pairs of hex digits.

   The length given is the number of bytes to be written.
*/

static void rsp_write_mem ( const rsp_buf * const buf )
{
  unsigned int    addr;
  int             len;

  assert( buf->data[0] == 'M' );

  if ( 2 != sscanf( buf->data, "M%x,%x:", &addr, &len ) )
  {
    throw std::runtime_error( "Illegal write memory packet." );
  }

  // Find the start of the data and check there is the amount we expect.
  const char * const symdat = ((const char *)memchr( buf->data, ':', GDB_BUF_MAX ) ) + 1;
  const int datlen = buf->len - (symdat - buf->data);

  // Sanity check.
  if ( len * 2 != datlen )
  {
    throw std::runtime_error( format_msg( "Illegal write memory packet: Write of %d data hex digits requested, but %d digits were supplied.",
                                          len * 2, datlen ) );
  }

  // Write the bytes to memory.

  // Put all the data into a single buffer, so it can be burst-written via JTAG.
  // One burst is much faster than many single-byte transactions.
  // NOTE: We don't support burst data accesses any more, but that may change in the future.

  std::vector< uint8_t > data;

  for ( int off = 0; off < len; off++ )
  {
    const unsigned char nyb1 = parse_hex_digit( symdat[ off * 2     ] );
    const unsigned char nyb2 = parse_hex_digit( symdat[ off * 2 + 1 ] );
    data.push_back( (nyb1 << 4) | nyb2 );
  }

  const bool error_bit = dbg_cpu0_write_mem( addr, len, &data );

  if ( error_bit )
    put_str_packet( rsp.client_fd, STD_ERROR_CODE );
  else
    send_ok_packet( rsp.client_fd );
}


/* Write to a single register.

   The registers follow the GDB sequence for OR1K: GPR0 through GPR31, PC
   (i.e. SPR NPC) and SR (i.e. SPR SR). The register is specified as a
   sequence of bytes in target endian order.

   Each byte is packed as a pair of hex digits.

   @param[in] buf  The original packet request.
*/

static void rsp_write_reg ( const rsp_buf * const buf )
{
  unsigned int  regnum;
  char          valstr[9];      // Allow for EOS on the string

  // Break out the fields from the data.
  if ( 2 != sscanf (buf->data, "P%x=%8s", &regnum, valstr ) )
  {
    throw std::runtime_error( "Illegal write register packet." );
  }

  // Set the relevant register.  Must translate between GDB register numbering and hardware reg. numbers.

  uint16_t spr_number;
  bool ignore = false;

  switch ( regnum )
  {
  case PPC_REGNUM:
    // The OR10 CPU does not support this register, any writes to it are ignored here.
    // GDB should not try to read and write this register any more.
    spr_number = (uint16_t) -1;
    ignore = true;
    break;

  case NPC_REGNUM:
    spr_number = SPR_NPC;
    break;

  case SR_REGNUM:
    spr_number = SPR_SR;
    break;

  default:
    if ( regnum >= 0 && regnum < MAX_GPRS )
    {
      spr_number = SPR_GPR_BASE + regnum;
      break;
    }

    throw std::runtime_error( format_msg( "Unknown register number %d processing a write register packet.", regnum ) );
  }

  if ( !ignore )
  {
    const uint32_t new_val = parse_reg_32_from_hex( valstr );
    dbg_cpu0_write_spr_e( spr_number, new_val );
  }

  send_ok_packet( rsp.client_fd );
}


// Handle an RSP qRcmd request, which provides pass-through access to the target system.
// The user can trigger qRcmd requests with GDB's "monitor" command.
// The qRcmd commands are target specific, but targets should implement at least a "help" command.

  static const std::string READSPR_PREFIX ( "readspr " );
  static const std::string WRITESPR_PREFIX( "writespr " );

static void rsp_pass_through_command ( const rsp_buf * const buf, const int cmd_str_pos )
{
  // The actual command follows the "qRcmd," RSP request in ASCII encoded ib hex.

  std::string cmd = hex2ascii( &(buf->data[ cmd_str_pos ]) );

  // printf( "Monitor cmd: %s\n", cmd.c_str() );

  if ( cmd == "help" )
  {
    std::string help_text = "Available target-specific commands:\n";
    help_text += "- help\n";
    help_text += "- readspr <register number in hex>\n";
    help_text += "  The register value is printed in hex.\n";
    help_text += "- writespr <register number in hex> <register value in hex>\n";

    const std::string help_text_hex = ascii2hex( help_text.c_str() );

    put_str_packet( rsp.client_fd, &help_text_hex );
  }
  else if ( str_remove_prefix( &cmd, &READSPR_PREFIX ) )
  {
    unsigned int regno;

    // Parse and return error if we fail.
    if ( 1 != sscanf( cmd.c_str(), "%x", &regno ) )
    {
      throw std::runtime_error( "Error parsing the target-specific 'readspr' command." );
    }

    if ( regno >= MAX_SPRS )
    {
      throw std::runtime_error( format_msg( "Error parsing the target-specific 'readspr' command: SPR number %u is out of range.", regno ) );
    }

    uint32_t reg_val;
    dbg_cpu0_read_spr_e( uint16_t( regno ), &reg_val );

    const std::string reply_str     = format_msg( "%08x\n", reg_val );
    const std::string reply_str_hex = ascii2hex( reply_str.c_str() );

    put_str_packet( rsp.client_fd, &reply_str_hex );
  }
  else if ( str_remove_prefix( &cmd, &WRITESPR_PREFIX ) )
  {
    unsigned int       regno;
    unsigned long int  val;

    if ( 2 != sscanf( cmd.c_str(), "%x %lx", &regno, &val ) )
    {
      throw std::runtime_error( "Error parsing the target-specific 'writespr' command." );
    }

    if ( regno >= MAX_SPRS )
    {
      throw std::runtime_error( format_msg( "Error parsing the target-specific 'writespr' command: SPR number %u is out of range.", regno ) );
    }

    dbg_cpu0_write_spr_e( uint16_t( regno ), val );

    send_ok_packet( rsp.client_fd );
  }
  else
      throw std::runtime_error( "Unknown target-specific command." );
}


static void rsp_query ( const rsp_buf * const buf )
{
  s_scratch.clear();

  int cmd_str_pos;

  for ( cmd_str_pos = 1; cmd_str_pos < buf->len; ++cmd_str_pos )
  {
    const char c = buf->data[ cmd_str_pos ];

    if ( c == ',' || c == ':' || c == ';' )
      break;

    s_scratch.push_back( c );
  }

  if ( s_scratch.empty() )
    throw std::runtime_error( "Illegal query packet: the queried name is empty." );

  if ( s_scratch == "C" )
  {
    // Return the current thread ID (unsigned hex). A null response
    // indicates to use the previously selected thread. Since we do not
    // support a thread concept, this is the appropriate response.
    put_str_packet( rsp.client_fd, "" );
  }
  else if ( s_scratch == "Offsets" )
  {
    // We don't support any relocations, so report zero for all sections.
    put_str_packet( rsp.client_fd, "Text=0;Data=0;Bss=0" );
  }
  else if ( s_scratch == "Rcmd" && buf->data[ cmd_str_pos ] == ',' )
  {
    rsp_pass_through_command( buf, cmd_str_pos + 1 );
  }
  else if ( s_scratch == "Supported" )
  {
    // Report a list of the features we support. For now we just ignore any
    // supplied specific feature queries, but in the future these may be
    // supported as well. Note that the packet size allows for 'G' + all the
    // registers sent to us, or a reply to 'g' with all the registers and an
    // EOS so the buffer is a well formed string.
    char reply[30];

    if ( int( sizeof(reply) ) <= sprintf( reply, "PacketSize=%x", GDB_BUF_MAX - 1 ) )
      assert( false );

    put_str_packet( rsp.client_fd,  reply );
  }
  else if ( s_scratch == "Symbol" )
  {
    // GDB is offering to serve symbol look-up requests, but there's nothing we
    // want to look up now.
    send_ok_packet( rsp.client_fd );
  }
  else if ( s_scratch == "Attached" )
  {
    // GDB is inquiring whether it created a process or attached to an
    // existing one. We don't support this feature. Note this query packet
    // may have a ':' and a PID included.
    send_unknown_command_reply( rsp.client_fd );
  }
  else if ( s_scratch == "TStatus" )
  {
    // GDB is inquiring whether a trace is running.
    // We don't support the trace feature, so respond with an
    // empty packet.  Note that if we respond 'no' with a "T0"
    // packet, GDB will send us further queries about tracepoints.
    send_unknown_command_reply( rsp.client_fd );
  }
  else
  {
    // throw std::runtime_error( format_msg( "Error processing a GDB query packet: unknown queried name \"%s\".", s_scratch.c_str() ) );

    assert( false );
    send_unknown_command_reply( rsp.client_fd );
  }
}


/* Generic processing of a step request

   The signal may be EXCEPT_NONE if there is no exception to be
   handled. Currently the exception is ignored.

   The single step flag is set in the debug registers and then the processor
   is unstalled.

   @param[in] addr    Address from which to step
   @param[in] except  The exception to use (or EXCEPT_NONE if none)
*/

static void rsp_step_generic ( const unsigned long int except )
{
  assert( !rsp.is_target_running );

  // Clear Debug Reason Register, which holds the reason why the CPU stalled the last time.
  dbg_cpu0_write_spr_e( SPR_DRR, 0 );

  // Set the single step trigger in Debug Mode Register 1 and set traps to be
  // handled by the debug unit in the Debug Stop Register.
  if ( !rsp.is_in_single_step_mode )
  {
    set_single_step_mode( true );
  }

  unstall_cpu();
  rsp.cpu_poll_speed = CPS_FAST;
}


/* Handle a RSP step request

   Parse the command to see if there is an address. Uses the underlying
   generic step function, with EXCEPT_NONE.

   @param[in] buf  The full step packet
*/

static void rsp_step ( const rsp_buf * const buf )
{
  assert( buf->data[0] == 's' );

  unsigned long int addr;  // The address to step from, if any.

  if ( buf->len > 1 )  // If there is more than the one 's' character.
  {
    if( 1 != sscanf( &buf->data[1], "%lx", &addr ) )
    {
      throw std::runtime_error( "Illegal step packet." );
    }

    throw std::runtime_error( "The 'step' command with a given address is not supported yet." );
  }

  rsp_step_generic( EXCEPT_NONE );
}


// Handle a RSP 'v' packet
//
//   These are commands associated with executing the code on the target

static void rsp_vpkt ( const rsp_buf * const buf )
{
  s_scratch.clear();

  for ( int i = 1; i < buf->len; ++i )
  {
    const char c = buf->data[ i ];

    if ( c == ';' || c == '?' )
      break;

    s_scratch.push_back( c );
  }

  if ( s_scratch.empty() )
    throw std::runtime_error( "Illegal 'v' packet: the operation name is empty." );

  if ( s_scratch == "vCont?" )
  {
    // We don't support the vCont command, which is only a must if we have reported
    // support for the multiprocess extensions.
    send_unknown_command_reply( rsp.client_fd );
  }
  else if ( s_scratch == "Kill" )
  {
    kill_request();
    send_ok_packet( rsp.client_fd );
  }
  else
  {
    send_unknown_command_reply( rsp.client_fd );
  }
}


void process_client_command ( const rsp_buf * const buf )
{
  if ( rsp.is_target_running )
  {
    // printf( "BREAK received while CPU running.\n" );
    if ( buf->data[0] == GDB_RSP_BREAK_CMD )
    {
      stall_cpu();
      collect_cpu_stop_reason( true );
      send_signal_reply_packet();
      rsp.cpu_poll_speed = CPS_SLOW;
      return;
    }

    throw std::runtime_error( "A GDB RSP command was received while the CPU was running, which is an indication "
                              "that the RSP handling got out of sync." );
  }

  assert( rsp.cpu_poll_speed == CPS_SLOW );

  switch ( buf->data[0] )
  {
  case GDB_RSP_BREAK_CMD:
    // The target was not running and a break command was received. This can happen if the user
    // issues a break (with Ctrl+C) but the CPU just stalled for anothe reason.
    send_signal_reply_packet();
    break;

  case '!':
    // Request for extended remote mode, which we do support.
    send_ok_packet( rsp.client_fd );
    break;

  case '?':
    send_signal_reply_packet();
    break;

  case 'c':
    rsp_continue( buf );
    break;

  case 'g':
    rsp_read_all_regs();
    break;

  case 'H':
    // Set the thread number of any subsequent operations.
    // Hc is for step and continue operations, Hg for all other operations.
    // The thread number can be -1 for all threads, a thread number, or 0 for "just pick any thread".
    // We only support one thread, so ignore all arguments and just reply "OK"
    send_ok_packet( rsp.client_fd );
    break;

  case 'k':
    kill_request();
    break;

  case 'm':
    rsp_read_mem( buf );
    break;

  case 'M':
    rsp_write_mem( buf );
    break;

  case 'P':
    rsp_write_reg( buf );
    break;

  case 'q':
    // General query packets.
    rsp_query( buf );
    break;

  case 's':
    // Single step (one high level instruction). This could be hard without DWARF2 info.
    rsp_step( buf );
    break;

  case 'v':
    // Any one of a number of packets to control execution
    rsp_vpkt( buf );
    break;


  // ----- These are all packets that we have decided not to support -----

  case 'Z':  // We don't support breakpoints yet. GDB will read and write memory itself
             // in order to place the "l.trap" instruction at the breakpoint positions.
  case 'D':  // Detach GDB. I'm not sure what to do in this case. If you type "detach" in the current
             // GDB version it does not close the connection and it triggers error message
             // "A problem internal to GDB has been detected".

  case 'X':  // We don't support binary memory writes. The old code did, so it should not be hard
             // to port it to this new implementation. This is only an optimisation, as GDB
             // will fall back to using text-based memory writes (see the 'M' command).
    send_unknown_command_reply( rsp.client_fd );
    break;

  default:
    // Assert on all unsupported packets that were not already known to the developer. This helps catch bugs.
    #ifndef NDEBUG
      printf( "Unknown RSP packet received: %s\n", format_packet_for_tracing_purposes( buf ).c_str() );
      assert( false );
    #endif

    send_unknown_command_reply( rsp.client_fd );
    break;
  }
}


void poll_cpu ( void )
{
  // printf( "Polling the CPU..." );

  const bool is_stalled = dbg_cpu0_is_stalled();

  // printf( "OK, is stalled: %s\n", is_stalled ? "yes" : "no" );

  if ( rsp.is_target_running && is_stalled )
  {
    rsp.is_target_running = false;
    collect_cpu_stop_reason( false );
    send_signal_reply_packet();
    rsp.cpu_poll_speed = CPS_SLOW;
  }
}


void check_connection_with_cpu_is_still_there ( void )
{
  dbg_cpu0_is_stalled();
}

void enable_or10_jtag_trace ( const bool enable_jtag_trace )
{
  dgb_enable_jtag_trace( enable_jtag_trace );
}
