/*
   Copyright (C) 2012 R. Diez, the code was almost complete rewritten.
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


// TODO: The old code has always called cable_flush() after a transaction, is that really necessary?
//       If so, which cables do need it?
// extern int cable_flush ( void );

// Returns the error bit read back.

static bool wait_for_cpu_ack ( void )
{
  jtag_discard_postfix_bits();

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

    return error_bit;
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error reading from CPU SPR group number: %u, reg number: %u: %s",
                                          (unsigned)(cpu_spr_reg_number >> 11),
                                          (unsigned)(cpu_spr_reg_number & 0x7FF),
                                          e.what() ) );
  }
}


void dbg_cpu0_read_spr_e ( const uint16_t cpu_spr_reg_number, uint32_t * const cpu_spr_reg_value )
{
  if ( dbg_cpu0_read_spr( cpu_spr_reg_number, cpu_spr_reg_value ) )
  {
    throw std::runtime_error( format_msg( "Error reading from CPU SPR group number: %u, reg number: %u: The CPU JTAG interface returned an error indication.",
                                          (unsigned)(cpu_spr_reg_number >> 11),
                                          (unsigned)(cpu_spr_reg_number & 0x7FF) ) );
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
    const bool error_bit = write_spr( cpu_spr_reg_number, cpu_spr_reg_value );

    finish_and_leave_a_dbg_nop_cmd_in_place();

    return error_bit;
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error writing to CPU SPR group number: %u, reg number: %u, new value: 0x%08X: %s",
                                          (unsigned)(cpu_spr_reg_number >> 11),
                                          (unsigned)(cpu_spr_reg_number & 0x7FF),
                                          (unsigned)cpu_spr_reg_value,
                                          e.what() ) );
  }
}


void dbg_cpu0_write_spr_e ( const uint16_t cpu_spr_reg_number, const uint32_t cpu_spr_reg_value )
{
  if ( dbg_cpu0_write_spr( cpu_spr_reg_number, cpu_spr_reg_value ) )
  {
    throw std::runtime_error( format_msg( "Error writing to CPU SPR group number: %u, reg number: %u, new value: 0x%08X: The CPU JTAG interface returned an error indication.",
                                          (unsigned)(cpu_spr_reg_number >> 11),
                                          (unsigned)(cpu_spr_reg_number & 0x7FF),
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
    throw std::runtime_error( format_msg( "Error during a combined write+read operation on CPU SPR group number: %u, reg number: %u, value written: 0x%08X: %s",
                                          (unsigned)(cpu_spr_reg_number >> 11),
                                          (unsigned)(cpu_spr_reg_number & 0x7FF),
                                          (unsigned)cpu_spr_reg_value_to_write,
                                          e.what() ) );
  }
}


bool dbg_cpu0_is_stalled ( void )
{
  try
  {
    tap_move_from_idle_to_shift_dr();

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

    uint8_t bit_read;
    jtag_read_write_bit( 0, &bit_read );

    const bool ret = ( bit_read != 0 );

    finish_and_leave_a_dbg_nop_cmd_in_place();

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
//       may contain fewer bytes than requested.

void dbg_cpu0_read_mem ( const uint32_t start_addr,
                         const uint32_t byte_count,
                         std::vector< uint8_t > * const data_read )
{
  if ( !is_aligned_4_len( start_addr ) )
    throw std::runtime_error( format_msg( "Reading from unaligned memory address 0x%08X is not supported yet.", unsigned(start_addr) ) );

  if ( !is_aligned_4_len( byte_count ) )
    throw std::runtime_error( format_msg( "Reading from memory with an unaligned length of %d is not supported yet.", unsigned(byte_count) ) );

  for ( unsigned i = 0; i < byte_count / 4; ++i )
  {
    const uint32_t addr = start_addr + i * 4;

    uint32_t val;
    const bool error_bit = dbg_cpu0_write_and_read_spr( SPR_DU_READ_MEM_ADDR, addr, &val );

    if ( error_bit )
    {
      // printf("Error bit set at mem addr: 0x%08X\n", addr );
      break;
    }

    // printf("Mem addr: 0x%08X, value read: 0x%08X\n", addr, val );

    // Note that this assumes that the OR10 CPU is big endian.
    assert( sizeof( val ) == 4 );

    uint8_t b1;
    uint8_t b2;
    uint8_t b3;
    uint8_t b4;
    break_up_into_bytes( val, &b1, &b2, &b3, &b4 );

    data_read->push_back( b1 );
    data_read->push_back( b2 );
    data_read->push_back( b3 );
    data_read->push_back( b4 );
  }
}


// Returns true if there was an error writing to memory.

bool dbg_cpu0_write_mem ( const uint32_t start_addr,
                          const uint32_t byte_count,
                          const std::vector< uint8_t > * const data_to_write )
{
  if ( !is_aligned_4_len( start_addr ) )
    throw std::runtime_error( format_msg( "Writing to unaligned memory address 0x%08X is not supported yet.", unsigned(start_addr) ) );

  const int rest_byte_count = byte_count % 4;

  unsigned i;
  for ( i = 0; i < byte_count / 4; ++i )
  {
    const uint32_t addr = start_addr + i * 4;

    // Note that this assumes that the OR10 CPU is big endian.
    const uint32_t val = ( (*data_to_write)[ i * 4     ] << 24 ) |
                         ( (*data_to_write)[ i * 4 + 1 ] << 16 ) |
                         ( (*data_to_write)[ i * 4 + 2 ] << 8  ) |
                         ( (*data_to_write)[ i * 4 + 3 ] );

    // printf( "Writing to mem addr: 0x%08X, value: 0x%08X\n", addr, val );

    if ( dbg_cpu0_write_spr( OR1200_DU_WRITE_MEM_ADDR, addr ) )
      return true;

    if ( dbg_cpu0_write_spr( OR1200_DU_WRITE_MEM_DATA, val ) )
      return true;
  }


  // Write the last (unaligned) bytes of data.
  if ( rest_byte_count != 0 )
  {
    uint32_t data_pos = i * 4;
    const uint32_t addr = start_addr + data_pos;

    uint32_t val;
    const bool error_bit = dbg_cpu0_write_and_read_spr( SPR_DU_READ_MEM_ADDR, addr, &val );

    if ( error_bit )
    {
      // printf("Error bit set at mem addr: 0x%08X\n", addr );
      return true;
    }

    uint8_t b1;
    uint8_t b2;
    uint8_t b3;
    uint8_t b4;
    break_up_into_bytes( val, &b1, &b2, &b3, &b4 );

    b1 = (*data_to_write)[ data_pos++ ];

    if ( data_pos < byte_count )
      b2 = (*data_to_write)[ data_pos++ ];

    if ( data_pos < byte_count )
      b3 = (*data_to_write)[ data_pos++ ];

    assert( data_pos == byte_count );

    const uint32_t new_val = assemble_bytes( b1, b2, b3, b4 );

    if ( dbg_cpu0_write_spr( OR1200_DU_WRITE_MEM_ADDR, addr ) )
      return true;

    if ( dbg_cpu0_write_spr( OR1200_DU_WRITE_MEM_DATA, new_val ) )
      return true;
  }

  return false;
}
