/*
   Copyright (C) 2012 R. Diez, the code was almost completely rewritten.
   Copyright (C) 2009 - 2011 Nathan Yawn, nyawn@opencores.net
   based on code from jp2 by Marko Mlinar, markom@opencores.org

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

#include "dbg_api.h"  // The include file for this module should come first.

#include <stdio.h>
#include <assert.h>
#include <stdarg.h>

#include <stdexcept>

#include "chain_commands.h"
#include "errcodes.h"
#include "utilities.h"
#include "string_utils.h"
#include "spr-defs.h"


#define DEBUG_CMD_LEN 3

#define DEBUG_CMD_NOP            0
#define DEBUG_CMD_IS_CPU_STALLED 1
#define DEBUG_CMD_WRITE_CPU_SPR  2
#define DEBUG_CMD_READ_CPU_SPR   3

#define BITS_PER_BYTE  8


static bool s_enable_jtag_trace;


void dgb_enable_jtag_trace ( const bool enable_jtag_trace )
{
  s_enable_jtag_trace = enable_jtag_trace;
}

static void trace_jtag ( const char * const format_str, ... )
{
  if ( !s_enable_jtag_trace )
    return;

  static const char TRACE_PREFIX[] = "Debug op: ";

  va_list arg_list;
  va_start( arg_list, format_str );

  printf( "%s", TRACE_PREFIX );
  vprintf( format_str, arg_list );

  va_end( arg_list );
}


static std::string decode_spr_number ( const uint16_t cpu_spr_reg_number )
{
  return format_msg( "CPU SPR group number: %u, reg number: %u",
                     (unsigned)(cpu_spr_reg_number >> 11),
                     (unsigned)(cpu_spr_reg_number & 0x7FF) );
}


// TODO: The old code has always called cable_flush() after a transaction, is that really necessary?
//       If so, which cables do need it?
// extern int cable_flush ( void );

// Returns the error bit read back.

static bool wait_for_cpu_ack ( void )
{
  jtag_discard_postfix_bits();

  trace_jtag( "Waiting for a '1' bit to signal operation completion...\n" );

  // Wait for a '1' bit that indicates the operation is complete.
  // POSSIBLE OPTIMISATION: We could read several bits at once here.

  for ( ; ; )
  {
    uint8_t bit_read;
    jtag_read_write_bit( 0, &bit_read );

    if ( bit_read != 0 )
      break;
  }

  // Read the error bit.

  uint8_t error_bit_read;
  jtag_read_write_bit( 0, &error_bit_read );

  trace_jtag( "Operation complete, the error bit read was %c.\n", error_bit_read ? '1' : '0' );

  return error_bit_read ? true : false;
}


void finish_and_leave_a_dbg_nop_cmd_in_place ( void )
{
  // POSSIBLE OPTIMISATION: DEBUG_CMD_NOP is made up of zeros, and we have just shifted a number
  //                        of them in. We may have shifted enough in, so that there is
  //                        a DEBUG_CMD_NOP already in place.
  //                        Alternatively, if we knew what the next debug command is, we could write
  //                        it here instead of flushing the old data out.

  // Set TMS during the last bit transfer -> goes then to state EXIT1_DR.
  jtag_shift_by_prefix_bits_with_ending_tms( DEBUG_CMD_LEN );

  tap_move_from_exit_1_to_idle();
}


static void read_spr ( uint32_t * const cpu_spr_reg_value )
{
  // Read the 32 bits with the operation result.
  assert( sizeof( *cpu_spr_reg_value ) * BITS_PER_BYTE == 32 );
  const uint32_t zeros = 0;
  assert( sizeof( *cpu_spr_reg_value ) == sizeof( zeros ) );

  jtag_read_write_stream( &zeros,
                          cpu_spr_reg_value,
                          sizeof( zeros ) * BITS_PER_BYTE,
                          false );
}


bool dbg_cpu0_read_spr ( const uint16_t cpu_spr_reg_number, uint32_t * const cpu_spr_reg_value )
{
  try
  {
    trace_jtag( "Reading %s...\n", decode_spr_number(cpu_spr_reg_number).c_str() );
    tap_move_from_idle_to_shift_dr();

    const uint32_t read_spr_cmd = ( DEBUG_CMD_READ_CPU_SPR << sizeof(cpu_spr_reg_number) * BITS_PER_BYTE ) | cpu_spr_reg_number;

    const int read_spr_cmd_bit_len = DEBUG_CMD_LEN + sizeof(cpu_spr_reg_number) * BITS_PER_BYTE;

    assert( read_spr_cmd_bit_len <= int( sizeof( read_spr_cmd ) * BITS_PER_BYTE ) );

    jtag_write_stream( &read_spr_cmd,
                       read_spr_cmd_bit_len,
                       true  // Set TMS during the last bit transfer, goes to state EXIT1_DR.
                   );

    // Moves the state machine from EXIT1-DR -> Update-DR -> IDLE.
    // Going through Update-DR triggers the actual CPU SPR read.
    tap_move_from_exit_1_to_idle();

    tap_move_from_idle_to_shift_dr();

    const bool error_bit = wait_for_cpu_ack();

    if ( error_bit )
    {
      *cpu_spr_reg_value = 0;
    }
    else
    {
      read_spr( cpu_spr_reg_value );
    }

    finish_and_leave_a_dbg_nop_cmd_in_place();

    trace_jtag( "Finished reading %s.\n", decode_spr_number(cpu_spr_reg_number).c_str() );

    return error_bit;
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error reading from %s: %s",
                                          decode_spr_number(cpu_spr_reg_number).c_str(),
                                          e.what() ) );
  }
}


void dbg_cpu0_read_spr_e ( const uint16_t cpu_spr_reg_number, uint32_t * const cpu_spr_reg_value )
{
  if ( dbg_cpu0_read_spr( cpu_spr_reg_number, cpu_spr_reg_value ) )
  {
    throw std::runtime_error( format_msg( "Error reading from %s: The CPU JTAG interface returned an error indication.",
                                          decode_spr_number(cpu_spr_reg_number).c_str() ) );
  }
}


static bool write_spr ( const uint16_t cpu_spr_reg_number, const uint32_t cpu_spr_reg_value )
{
  tap_move_from_idle_to_shift_dr();

  uint32_t write_spr_cmd[2];
  write_spr_cmd[0] = cpu_spr_reg_value;
  write_spr_cmd[1] = ( DEBUG_CMD_WRITE_CPU_SPR << sizeof(cpu_spr_reg_number) * BITS_PER_BYTE ) | cpu_spr_reg_number;

  const int write_spr_cmd_bit_len = sizeof(cpu_spr_reg_value) * BITS_PER_BYTE +
                                    DEBUG_CMD_LEN +
                                     sizeof(cpu_spr_reg_number) * BITS_PER_BYTE;

  assert( write_spr_cmd_bit_len <= int( sizeof( write_spr_cmd ) * BITS_PER_BYTE ) );

  jtag_write_stream( write_spr_cmd,
                     write_spr_cmd_bit_len,
                     true  // Set TMS during the last bit transfer, goes to state EXIT1_DR.
                   );

  // Moves the state machine from EXIT1-DR -> Update-DR -> IDLE.
  // Going through Update-DR triggers the actual CPU SPR write.
  tap_move_from_exit_1_to_idle();

  tap_move_from_idle_to_shift_dr();

  return wait_for_cpu_ack();
}


bool dbg_cpu0_write_spr ( const uint16_t cpu_spr_reg_number, const uint32_t cpu_spr_reg_value )
{
  try
  {
    trace_jtag( "Writing %s...\n", decode_spr_number(cpu_spr_reg_number).c_str() );

    const bool error_bit = write_spr( cpu_spr_reg_number, cpu_spr_reg_value );

    finish_and_leave_a_dbg_nop_cmd_in_place();

    trace_jtag( "Finished writing %s.\n", decode_spr_number(cpu_spr_reg_number).c_str() );

    return error_bit;
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error writing to %s, new value: 0x%08X: %s",
                                          decode_spr_number(cpu_spr_reg_number).c_str(),
                                          (unsigned)cpu_spr_reg_value,
                                          e.what() ) );
  }
}


void dbg_cpu0_write_spr_e ( const uint16_t cpu_spr_reg_number, const uint32_t cpu_spr_reg_value )
{
  if ( dbg_cpu0_write_spr( cpu_spr_reg_number, cpu_spr_reg_value ) )
  {
    throw std::runtime_error( format_msg( "Error writing to %s, new value: 0x%08X: The CPU JTAG interface returned an error indication.",
                                          decode_spr_number(cpu_spr_reg_number).c_str(),
                                          (unsigned)cpu_spr_reg_value ) );
  }
}


// Writes a CPU SPR and reads the new value in a single transaction.

static bool dbg_cpu0_write_and_read_spr ( const uint16_t cpu_spr_reg_number,
                                          const uint32_t cpu_spr_reg_value_to_write,
                                          uint32_t * const cpu_spr_reg_value_read )
{
  try
  {
    const bool error_bit = write_spr( cpu_spr_reg_number, cpu_spr_reg_value_to_write );

    if ( error_bit )
    {
      *cpu_spr_reg_value_read = 0;
    }
    else
    {
      read_spr( cpu_spr_reg_value_read );
    }

    finish_and_leave_a_dbg_nop_cmd_in_place();

    return error_bit;
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error during a combined write+read operation on %s, value written: 0x%08X: %s",
                                          decode_spr_number(cpu_spr_reg_number).c_str(),
                                          (unsigned)cpu_spr_reg_value_to_write,
                                          e.what() ) );
  }
}


bool dbg_cpu0_is_stalled ( void )
{
  try
  {
    trace_jtag( "Querying CPU stall status...\n" );

    tap_move_from_idle_to_shift_dr();

    trace_jtag( "Writing a DEBUG_CMD_IS_CPU_STALLED command.\n" );

    const uint32_t is_stalled_cmd = DEBUG_CMD_IS_CPU_STALLED;

    const int is_stalled_cmd_bit_len = DEBUG_CMD_LEN;

    assert( is_stalled_cmd_bit_len <= int( sizeof( is_stalled_cmd ) * BITS_PER_BYTE ) );

    jtag_write_stream( &is_stalled_cmd,
                       is_stalled_cmd_bit_len,
                       true  // Set TMS during the last bit transfer, goes to state EXIT1_DR.
                     );

    // Moves the state machine from EXIT1-DR -> Update-DR -> IDLE.
    // Going through Update-DR triggers the actual CPU "is stalled" query.
    tap_move_from_exit_1_to_idle();

    tap_move_from_idle_to_shift_dr();

    jtag_discard_postfix_bits();

    trace_jtag( "Reading the 'is stalled' bit...\n" );

    uint8_t bit_read;
    jtag_read_write_bit( 0, &bit_read );

    const bool ret = ( bit_read != 0 );

    finish_and_leave_a_dbg_nop_cmd_in_place();

    trace_jtag( "Finished querying CPU stall status, result is: %s.\n", ret ? "stalled" : "not stalled" );

    return ret;
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error querying whether the CPU is stalled: %s",
                                          e.what() ) );
  }
}


static void break_up_into_bytes ( const uint32_t val,
                                  uint8_t * const b1,
                                  uint8_t * const b2,
                                  uint8_t * const b3,
                                  uint8_t * const b4 )
{
  *b1 =  val >> 24;
  *b2 = (val >> 16) & 0xFF;
  *b3 = (val >>  8) & 0xFF;
  *b4 = val & 0xFF;
}


static uint32_t assemble_bytes ( const uint8_t b1,
                                 const uint8_t b2,
                                 const uint8_t b3,
                                 const uint8_t b4 )
{
    return ( b1 << 24 ) |
           ( b2 << 16 ) |
           ( b3 << 8  ) |
           ( b4 );
}


// NOTE: If the CPU reports an error reading from memory, this routine stops, so the data returned
//       may contain fewer bytes than requested. That matches the specification of GDB RSP command 'm addr,length'.

void dbg_cpu0_read_mem ( const uint32_t start_addr,
                         const uint32_t byte_count,
                         std::vector< uint8_t > * const data_read )
{
  if ( byte_count == 0 )
  {
    assert( false );
    return;
  }

  trace_jtag( "Reading from memory, address 0x%08X, byte count %u...\n", start_addr, byte_count );

  // The code below assumes that the OR10 CPU is big endian.
  //
  // This code can be optimised by having a central loop that reads 4-byte aligned data in chunks.
  //
  // If the debug interface supported setting the Wishbone 'sel' signal, we could read single bytes
  // and 16-bit words where necessary.

  uint32_t addr     = start_addr & 0xFFFFFFFC;
  unsigned byte_pos = start_addr % 4;

  uint8_t b1;
  uint8_t b2;
  uint8_t b3;
  uint8_t b4;

  uint32_t mem_val_1;
  const bool error_bit_1 = dbg_cpu0_write_and_read_spr( SPR_DU_READ_MEM_ADDR, addr, &mem_val_1 );
  if ( error_bit_1 )
  {
    // printf("Error bit set at mem addr: 0x%08X\n", addr );

    // Nothing else to do here, the caller will get fewer bytes than requested,
    // and that is the only error indication this routine is returning.
  }
  else
  {
    // printf("Mem addr: 0x%08X, value read: 0x%08X\n", addr, mem_val_1 );
    break_up_into_bytes( mem_val_1, &b1, &b2, &b3, &b4 );


    for ( unsigned i = 0; i < byte_count; ++i )
    {
      bool is_end_of_32_bit_word = false;

      switch ( byte_pos )
      {
      case 0: data_read->push_back( b1 ); break;
      case 1: data_read->push_back( b2 ); break;
      case 2: data_read->push_back( b3 ); break;
      case 3: data_read->push_back( b4 );
        is_end_of_32_bit_word = true;
        break;
      default:
        assert( false );
      }

      if ( is_end_of_32_bit_word )
      {
        byte_pos = 0;
        addr += 4;

        uint32_t mem_val_2;
        const bool error_bit_2 = dbg_cpu0_write_and_read_spr( SPR_DU_READ_MEM_ADDR, addr, &mem_val_2 );
        if ( error_bit_2 )
        {
          // printf("Error bit set at mem addr: 0x%08X\n", addr );
          break;
        }
        // printf("Mem addr: 0x%08X, value read: 0x%08X\n", addr, mem_val_2 );
        break_up_into_bytes( mem_val_2, &b1, &b2, &b3, &b4 );
      }
      else
      {
        byte_pos++;
      }
    }
  }

  trace_jtag( "Finished reading from memory, address 0x%08X, byte count %u.\n", start_addr, byte_count );
}


static bool dbg_cpu0_write_mem_2 ( const uint32_t start_addr,
                                   const uint32_t byte_count,
                                   const std::vector< uint8_t > * const data_to_write )
{
  if ( byte_count == 0 )
  {
    assert( false );
    return false;
  }

  assert( byte_count <= data_to_write->size() );

  // The code below assumes that the OR10 CPU is big endian.
  //
  // This code can be optimised by having a central loop that writes 4-byte aligned data in chunks.
  //
  // If the debug interface supported setting the Wishbone 'sel' signal, we could write single bytes
  // and 16-bit words where necessary.

  uint32_t addr     = start_addr & 0xFFFFFFFC;
  unsigned byte_pos = start_addr % 4;

  uint8_t b1;
  uint8_t b2;
  uint8_t b3;
  uint8_t b4;

  // If the start memory address is not aligned or we are not writing at least 4 bytes,
  // some of the bytes at the corresponding starting aligned 32-bit memory position will not be overwritten.
  // Therefore, we have to read the aligned 32-bit word beforehand,
  // modify just part of it, and then write the resulting 32-bit word later.
  if ( byte_pos != 0 || byte_count < 4 )
  {
    /*
    if ( byte_pos != 0 )
    {
      printf( "Unaligned at start by %d bytes.\n", byte_pos );
    }
    else if ( byte_count < 4 )
    {
      printf( "Unaligned length at start of %d bytes.\n", byte_count );
    }
    */

    uint32_t mem_val_1;

    const bool error_bit_1 = dbg_cpu0_write_and_read_spr( SPR_DU_READ_MEM_ADDR, addr, &mem_val_1 );
    if ( error_bit_1 )
    {
      // printf("Error bit set at mem addr: 0x%08X\n", addr );
      return true;
    }
    // printf("Mem addr: 0x%08X, value read: 0x%08X\n", addr, mem_val_1 );
    break_up_into_bytes( mem_val_1, &b1, &b2, &b3, &b4 );
  }


  for ( unsigned i = 0; ; )
  {
    assert( i < data_to_write->size() );

    const uint8_t current_byte = (*data_to_write)[ i ];
    bool is_end_of_32_bit_word = false;

    switch ( byte_pos )
    {
    case 0: b1 = current_byte; break;
    case 1: b2 = current_byte; break;
    case 2: b3 = current_byte; break;
    case 3: b4 = current_byte;
                 is_end_of_32_bit_word = true;
                 break;
    default:
      assert( false );
    }

    ++i;
    const bool should_exit_loop = ( i == byte_count );

    if ( is_end_of_32_bit_word || should_exit_loop )
    {
      assert( addr % 4 == 0 );

      if ( dbg_cpu0_write_spr( OR1200_DU_WRITE_MEM_ADDR, addr ) )
        return true;

      const uint32_t new_val = assemble_bytes( b1, b2, b3, b4 );

      if ( dbg_cpu0_write_spr( OR1200_DU_WRITE_MEM_DATA, new_val ) )
        return true;
    }

    if ( should_exit_loop )
      break;


    if ( is_end_of_32_bit_word )
    {
      byte_pos = 0;
      addr += 4;
    }
    else
    {
      byte_pos++;
    }


    // If less than 4 bytes are left, then not all of the 4 bytes in the next
    // 32-bit word will be overwritten. Therefore, we must load the existing 32-bit word
    // beforehand, in order to keep those values when we write the complete word at the end.

    const unsigned byte_count_left = byte_count - i;

    if ( is_end_of_32_bit_word && byte_count_left < 4 )
    {
      // printf( "Unaligned at end by %d bytes.\n", byte_count_left );
      uint32_t mem_val_3;

      assert( addr % 4 == 0 );

      const bool error_bit_3 = dbg_cpu0_write_and_read_spr( SPR_DU_READ_MEM_ADDR, addr, &mem_val_3 );
      if ( error_bit_3 )
      {
        // printf("Error bit set at mem addr: 0x%08X\n", addr );
        return true;
      }
      // printf("Mem addr: 0x%08X, value read: 0x%08X\n", addr, mem_val_3 );
      break_up_into_bytes( mem_val_3, &b1, &b2, &b3, &b4 );
    }
  }

  return false;
}


// Returns true if there was an error writing to memory.

bool dbg_cpu0_write_mem ( const uint32_t start_addr,
                          const uint32_t byte_count,
                          const std::vector< uint8_t > * const data_to_write )
{
  if ( byte_count == 0 )
  {
    assert( false );
    return false;
  }

  trace_jtag( "Writing to memory, address 0x%08X, byte count %u...\n", start_addr, byte_count );

  const bool ret = dbg_cpu0_write_mem_2 ( start_addr, byte_count, data_to_write );

  trace_jtag( "Finished writing to memory, address 0x%08X, byte count %u.\n", start_addr, byte_count );

  return ret;
}
