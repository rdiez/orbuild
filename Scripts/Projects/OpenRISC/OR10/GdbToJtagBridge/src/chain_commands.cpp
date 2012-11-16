/*
   Copyright (C) 2012  R.Diez
   Copyright (C) 2008 - 2010 Nathan Yawn, nyawn@opencores.net
   based on code from jp2 by Marko Mlinar, markom@opencores.org

   This file contains functions which perform mid-level transactions
   on a JTAG, such as setting a value in the TAP IR
   or doing a burst write on the JTAG chain.

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

#include "chain_commands.h"  // The include file for this module should come first.

#include <stdio.h>
#include <string.h>  // For memset().
#include <assert.h>
#include <stdarg.h>

#include <stdexcept>

#include "cable_api.h"
#include "bsdl.h"
#include "errcodes.h"
#include "string_utils.h"
#include "linux_utils.h"

#define debug(...) //fprintf(stderr, __VA_ARGS__ )


// Hardware-specific defines for the Altera Virtual JTAG interface
//
// Contains constants relevant to the Altera Virtual JTAG
// device, which are not included in the BSDL.
// As of this writing, these are constant across every
// device which supports virtual JTAG.

// These are commands for the FPGA's IR
#define ALTERA_CYCLONE_CMD_VIR     0x0E
#define ALTERA_CYCLONE_CMD_VDR     0x0C

// These defines are for the virtual IR (not the FPGA's)
// The virtual TAP was defined in hardware to match the OpenCores native
// TAP in both IR size and DEBUG command.
#define ALT_VJTAG_IR_SIZE    4
#define ALT_VJTAG_CMD_DEBUG  0x8


// Configuration data
static int global_IR_size = 0;
static int global_IR_prefix_bits = 0;
static int global_IR_postfix_bits = 0;
static int global_DR_prefix_bits = 0;
static int global_DR_postfix_bits = 0;
static unsigned int global_jtag_cmd_debug = 0;        // Value to be shifted into the TAP IR to select the debug unit (unused for virtual jtag)
static bool is_altera_virtual_jtag = 0;
static bool is_xilinx_bscan_internal_jtag = false;
static unsigned int vjtag_cmd_vir = ALTERA_CYCLONE_CMD_VIR;  // virtual IR-shift command for altera devices, may be configured on command line
static unsigned int vjtag_cmd_vdr = ALTERA_CYCLONE_CMD_VDR; // virtual DR-shift, ditto

static bool s_enable_bit_data_trace = false;
static const char BIT_DATA_TRACE_PREFIX[] = "JTAG bit data: ";
static std::string s_trace_buffer;


static void trace_jtag ( const char * const format_str, ... )
{
  if ( !s_enable_bit_data_trace )
    return;

  va_list arg_list;
  va_start( arg_list, format_str );

  printf( "%s", BIT_DATA_TRACE_PREFIX );
  vprintf( format_str, arg_list );

  va_end( arg_list );
}


///////////////////////////////////////////////////////////////////////
// Configuration

void config_set_IR_size(int size)
{
  global_IR_size = size;
}

void config_set_IR_prefix_bits(int bits)
{
  global_IR_prefix_bits = bits;
}

void config_set_IR_postfix_bits(int bits)
{
  global_IR_postfix_bits = bits;
}

void config_set_DR_prefix_bits(int bits)
{
  global_DR_prefix_bits = bits;
}

void config_set_DR_postfix_bits(int bits)
{
  global_DR_postfix_bits = bits;
}

void config_set_debug_cmd(unsigned int cmd)
{
  global_jtag_cmd_debug = cmd;
}

void config_set_alt_vjtag(unsigned char enable)
{
  is_altera_virtual_jtag = (enable) ? true : false;
}

void config_set_xilinx_bscan_internal_jtag ( bool enable )
{
  // The original adv_dbg_bridge needed a special trick when doing burst reads with Xilinx' internal JTAG,
  // but the current implementation does not seem to need such tricks any more,
  // therefore the flag below is not used at all.
  // In case something comes up in the future, here is the original comment about the trick:
  //   This is a kludge to work around oddities in the Xilinx BSCAN_* devices, and the
  //   adv_dbg_if state machine.  The debug FSM needs 1 TCK between UPDATE_DR above, and
  //   the CAPTURE_DR below, and the BSCAN_* won't provide it.  So, we force it, by putting the TAP
  //   in BYPASS, which makes the debug_select line inactive, which is AND'ed with the TCK line (in the xilinx_internal_jtag module),
  //   which forces it low.  Then we re-enable USER1/debug_select to make TCK high.  One TCK
  //   event, the hard way.

  is_xilinx_bscan_internal_jtag = enable;
}

// At present, all devices which support virtual JTAG use the same VIR/VDR
// commands.  But, if they ever change, these can be changed on the command line.
void config_set_vjtag_cmd_vir ( unsigned int cmd )
{
  vjtag_cmd_vir = cmd;
}

void config_set_vjtag_cmd_vdr ( unsigned int cmd )
{
  vjtag_cmd_vdr = cmd;
}

void config_set_trace ( const bool enable_bit_data_trace )
{
  s_enable_bit_data_trace = enable_bit_data_trace;
}


static void trace_outgoing_bit ( const uint8_t packet )
{
  if ( !s_enable_bit_data_trace )
    return;

  s_trace_buffer.clear();

  if ( packet & TMS )
  {
    s_trace_buffer += ", TMS=1";
  }
  if ( packet & TRST )
  {
    s_trace_buffer += ", TRST=1";
  }

  printf( "%sSent bit TDO=%c%s\n",
          BIT_DATA_TRACE_PREFIX,
          packet & TMS ? '1' : '0',
          s_trace_buffer.c_str() );
}


static void trace_outgoing_stream ( const uint32_t * const stream,
                                    const int len_bits,
                                    const bool set_TMS_during_the_last_bit_transfer )
{
  assert( len_bits > 0 );

  if ( !s_enable_bit_data_trace )
    return;

  s_trace_buffer.clear();

  int index = 0;
  int bits_this_index = 0;

  for ( int i = 0; i < len_bits; i++ )
  {
    const uint8_t out = (stream[index] >> bits_this_index) & 1;

    s_trace_buffer += out ? '1' : '0';

    bits_this_index++;

    if ( bits_this_index >= 32 )
    {
      index++;
      bits_this_index = 0;
    }
  }

  if ( set_TMS_during_the_last_bit_transfer )
    s_trace_buffer += ", last bit TMS=1";

  printf( "%sSent bits: %s\n",
          BIT_DATA_TRACE_PREFIX,
          s_trace_buffer.c_str() );
}


static void trace_incoming_stream ( const uint32_t * const stream,
                                    const int len_bits )
{
  assert( len_bits > 0 );

  if ( !s_enable_bit_data_trace )
    return;

  s_trace_buffer.clear();

  int index = 0;
  int bits_this_index = 0;

  for ( int i = 0; i < len_bits; i++ )
  {
    const uint8_t out = (stream[index] >> bits_this_index) & 1;

    s_trace_buffer += out ? '1' : '0';

    bits_this_index++;

    if ( bits_this_index >= 32 )
    {
      index++;
      bits_this_index = 0;
    }
  }

  printf( "%sReceived bits: %s\n",
          BIT_DATA_TRACE_PREFIX,
          s_trace_buffer.c_str() );
}


////////////////////////////////////////////////////////////////////
// Operations to read / write data over JTAG

static void jtag_write_bit ( uint8_t packet  // See the TDO, TMS and TRST constants.
                           )
{
  trace_outgoing_bit( packet );
  throw_if_error( cable_write_bit( packet ) );
}

void jtag_read_write_bit ( const uint8_t packet,  // See the TDO, TMS and TRST constants.
                           uint8_t * const in_bit )
{
  trace_outgoing_bit( packet );

  throw_if_error( cable_read_write_bit( packet, in_bit ) );

  if ( s_enable_bit_data_trace )
    printf( "%sReceived bit TDI=%c\n",
            BIT_DATA_TRACE_PREFIX,
            *in_bit ? '1' : '0' );
}


// When set_TMS_during_the_last_bit_transfer is true, this function ensures the written data is in the desired JTAG chain position
// (past prefix bits) before sending TMS. The extra bits sent after the given out_data are padded with zeros.

void jtag_write_stream ( const uint32_t * const out_data,
                         const int length_bits,
                         const bool set_TMS_during_the_last_bit_transfer )
{
  if ( !set_TMS_during_the_last_bit_transfer )
  {
    trace_outgoing_stream( out_data, length_bits, false );

    const int err = cable_write_stream( out_data, length_bits, 0 );
    throw_if_error( err );
  }
  else if ( global_DR_prefix_bits == 0 )
  {
    trace_outgoing_stream( out_data, length_bits, true );

    const int err = cable_write_stream( out_data, length_bits, 1 );
    throw_if_error( err );
  }
  else
  {
    trace_outgoing_stream( out_data, length_bits, false );

    const int err1 = cable_write_stream( out_data, length_bits, 0 );
    throw_if_error( err1 );

    jtag_shift_by_prefix_bits_with_ending_tms( 0 );
  }
}


// When set_TMS_during_the_last_bit_transfer is true, this function ensures the written data is in the desired JTAG chain position
// (past prefix bits) before sending TMS. The extra bits sent after the given out_data are padded with zeros.

void jtag_read_write_stream ( const uint32_t * const out_data,
                              uint32_t * const in_data,
                              const int length_bits,
                              const bool set_TMS_during_the_last_bit_transfer )
{
  assert( global_DR_postfix_bits >= 0 );

  // If there are both prefix and postfix bits, we may shift more bits than strictly necessary.
  // If we shifted out the data while burning through the postfix bits, these shifts could be subtracted
  // from the number of prefix shifts.  However, that way leads to madness.
  if ( !set_TMS_during_the_last_bit_transfer )
  {
    trace_outgoing_stream( out_data, length_bits, false );

    const int err = cable_read_write_stream( out_data, in_data, length_bits, 0 );
    throw_if_error( err );

    trace_incoming_stream( in_data, length_bits );
  }
  else if ( global_DR_prefix_bits == 0 )
  {
    trace_outgoing_stream( out_data, length_bits, true );
    const int err = cable_read_write_stream( out_data, in_data, length_bits, 1 );
    throw_if_error( err );

    trace_incoming_stream( in_data, length_bits );
  }
  else
  {
    trace_outgoing_stream( out_data, length_bits, false );

    const int err1 = cable_read_write_stream( out_data, in_data, length_bits, 0 );
    throw_if_error( err1 );

    trace_incoming_stream( in_data, length_bits );

    jtag_shift_by_prefix_bits_with_ending_tms( 0 );
  }
}


#define BITS_PER_BYTE  8
#define JSZIIH_BUFFER_SIZE_IN_WORDS 64
static const int MAX_BITS_PER_CHUNK = JSZIIH_BUFFER_SIZE_IN_WORDS * sizeof(uint32_t) * BITS_PER_BYTE;

static void shift_chunk ( const int bit_count,
                          const bool set_TMS_during_the_last_bit_transfer )
{
  uint32_t buffer[ JSZIIH_BUFFER_SIZE_IN_WORDS ];
  memset( buffer, 0, sizeof(buffer) );

  assert( bit_count > 0 && bit_count <= MAX_BITS_PER_CHUNK );

  jtag_write_stream( buffer, bit_count, set_TMS_during_the_last_bit_transfer );
}


// Shifts as many zeros in as specified. The bits read back are discarded.

static void jtag_shift_zeros_in ( const int bit_count,
                                  const bool set_TMS_during_the_last_bit_transfer )
{
  int bit_left_count = bit_count;

  while ( bit_left_count > MAX_BITS_PER_CHUNK )
  {
    assert( false );  // TODO: I haven't tested this code yet.
    shift_chunk( MAX_BITS_PER_CHUNK, false );
    bit_left_count -= MAX_BITS_PER_CHUNK;
  }

  shift_chunk( bit_left_count, set_TMS_during_the_last_bit_transfer );
}


// Shifts so many zeros in as there are postfix bits. The bits read back are discarded.

void jtag_discard_postfix_bits ( void )
{
  // TODO: This only happens when there are other devices in the JTAG chain,
  //       and that hasn't been tested since the last time this source code was heavily modified.
  assert( global_DR_postfix_bits == 0 );

  if ( global_DR_postfix_bits > 0 )
    jtag_shift_zeros_in( global_DR_postfix_bits, false );
}


// Shifts so many zeros in as there are prefix bits plus the given amount.
// The bits read back are discarded.
// TMS is set during the last bit transfer.

void jtag_shift_by_prefix_bits_with_ending_tms ( const int extra_bit_count )
{
  // TODO: This only happens when there are other devices in the JTAG chain,
  //       and that hasn't been tested since the last time this source code was heavily modified.
  assert( global_DR_prefix_bits == 0 );

  const int total_bit_count = global_DR_prefix_bits + extra_bit_count;
  assert( total_bit_count > 0 );

  jtag_shift_zeros_in( total_bit_count, true );
}


//////////////////////////////////////////////////////////////////////
// Functions which operate on the JTAG TAP

// Leaves the TAP in the Run-Test/Idle state.

void tap_reset ( void )
{
  try
  {
    trace_jtag( "Resetting the TAP...\n" );

    // I don't know why we write a TDO bit value of 0 here,
    // it should not be necessary to reset the TAP.
    jtag_write_bit(0);

    // TODO: There is no need to wait, at least for the vpi cable.
    //       Under what circumstances or for what cables do we need to wait?
    wait_ms( 100 );

    // In case the JTAG connection does not have a TRST, reset it manually
    // by issuing at least 5 TMS impulses.
    // I don't know why we send 8 here, 5 should be enough according to the JTAG specification.
    for ( int i = 0; i < 8; i++ )
      jtag_write_bit(TMS);

    // In case the JTAG connection does have a TRST signal, use it to reset the TAP.
    // This step should actually not be needed after the reset step above.
    // If the TRST signal is not connected, then this will shift the TAP state machine
    // from the Test-Logic-Reset state to the Run-Test/Idle state.

    jtag_write_bit(TRST);

    wait_ms( 100 );

    // If TRST is connected and we were in the Test-Logic-Reset state,
    // this shifts the TAP state machine to the Run-Test/Idle state.
    // If TRST is not connnected and we were already in the Run-Test/Idle state,
    // this has no effect (it does not change the state).
    jtag_write_bit(0);

    trace_jtag( "Finished resetting the TAP.\n" );
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error resetting the JTAG interface: %s",
                                          e.what() ) );
  }
}


// Write the DEBUG instruction opcode to the IR register, one way or the other.

void set_ir_to_cpu_debug_module ( void )
{
  trace_jtag( "Setting the JTAG IR to address the CPU Debug Module...\n" );

  try
  {
    if( is_altera_virtual_jtag )
    {
      // Set for virtual IR shift.
      tap_set_ir(vjtag_cmd_vir);  // This is the altera virtual IR scan command
      jtag_write_bit(TMS);  // SELECT_DR SCAN
      jtag_write_bit(  0);  // CAPTURE_DR
      jtag_write_bit(  0);  // SHIFT_DR

      // Select debug scan chain in virtual IR.
      const uint32_t data = (0x1<<ALT_VJTAG_IR_SIZE)|ALT_VJTAG_CMD_DEBUG;
      jtag_write_stream( &data, (ALT_VJTAG_IR_SIZE+1),
                         true  // Set TMS during the last bit transfer -> EXIT1_DR
                       );
      jtag_write_bit(TMS);  // UPDATE_DR
      jtag_write_bit(  0);  // IDLE

      // This is a command to set an altera device to the "virtual DR shift" command.
      tap_set_ir( vjtag_cmd_vdr );
    }
    else
    {
      // Select debug scan chain and stay in it forever.
      tap_set_ir( global_jtag_cmd_debug );
    }
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error switching to the debug module of the OR10 TAP: %s",
                                          e.what() ) );
  }

  trace_jtag( "Finished setting the JTAG IR to address the CPU Debug Module.\n" );
}


// Moves a value into the TAP instruction register (IR).
// Includes adjustment for scan chain IR length.

static std::vector< uint32_t > ir_chain;

void tap_set_ir ( const unsigned instruction_opcode )
{
  trace_jtag( "Setting the JTAG IR to 0x%X...\n", instruction_opcode );

  int chain_size;
  int chain_size_words;
  int i;
  int startoffset, startshift;

  // Adjust desired IR with prefix, postfix bits to set other devices in the chain to BYPASS
  chain_size = global_IR_size + global_IR_prefix_bits + global_IR_postfix_bits;
  assert( chain_size >= 1 );
  chain_size_words = (chain_size/32)+1;
  assert( chain_size_words >= 1 );

  ir_chain.resize( chain_size_words );

  for(i = 0; i < chain_size_words; i++)
    ir_chain[i] = 0xFFFFFFFF;  // Set all other devices to BYPASS

  // Copy the IR value into the output stream
  startoffset = global_IR_postfix_bits/32;
  startshift = (global_IR_postfix_bits - (startoffset*32));
  ir_chain[startoffset] &= (instruction_opcode << startshift);
  ir_chain[startoffset] |= ~(0xFFFFFFFF << startshift);  // Put the 1's back in the LSB positions
  ir_chain[startoffset] |= (0xFFFFFFFF << (startshift + global_IR_size));  // Put 1's back in MSB positions, if any
  if((startshift + global_IR_size) > 32)
  { // Deal with spill into the next word
    ir_chain[startoffset+1] &= instruction_opcode >> (32-startshift);
    ir_chain[startoffset+1] |= (0xFFFFFFFF << (global_IR_size - (32-startshift)));  // Put the 1's back in the MSB positions
  }

  // Do the actual JTAG transaction. Note that we assume that the TAP is in the Run-Test/Idle state.
  debug("Set IR to 0x%X\n", instruction_opcode);
  jtag_write_bit(TMS); // SELECT_DR SCAN
  jtag_write_bit(TMS); // SELECT_IR SCAN

  jtag_write_bit(  0); // CAPTURE_IR
  jtag_write_bit(  0); // SHIFT_IR

  // Write data, EXIT1_IR.
  debug( "Setting IR, size %i, IR_size = %i, pre_size = %i, post_size = %i, data 0x%X\n",
         chain_size, global_IR_size, global_IR_prefix_bits, global_IR_postfix_bits, instruction_opcode );

  trace_outgoing_stream( &ir_chain.front(), chain_size, true );

  const int err = cable_write_stream( &ir_chain.front(), chain_size, 1 );  // Use cable_ call directly (not jtag_), so we don't add DR prefix bits
  throw_if_error( err );
  debug("Done setting IR\n");

  jtag_write_bit(TMS); // UPDATE_IR
  jtag_write_bit(  0); // IDLE

  trace_jtag( "Finished setting the JTAG IR.\n" );
}


void tap_move_from_idle_to_shift_dr ( void )
{
  trace_jtag( "Moving TAP from Idle to Shift-DR...\n" );

  jtag_write_bit(TMS);  // SELECT_DR SCAN
  jtag_write_bit(  0);  // CAPTURE_DR
  jtag_write_bit(  0);  // SHIFT_DR

  trace_jtag( "Finished moving TAP from Idle to Shift-DR.\n" );
}


void tap_move_from_exit_1_to_idle ( void )
{
  trace_jtag( "Moving TAP from Exit-1 to Idle...\n" );

  jtag_write_bit(TMS); // UPDATE_DR
  jtag_write_bit(  0); // IDLE

  trace_jtag( "Finished moving TAP from Exit-1 to Idle.\n" );
}


// This function attempts to scan the JTAG chain and determine how many devices are present
// and what their IDCODEs are (if supported).
// There is no easy way to automatically determine the length of the IR registers -
// this must be read from a BSDL file, if IDCODE is supported.
// When IDCODE is not supported, the IR length of the target device must be entered on the command line.
// Devices which do not support IDCODE will get an IDCODE value of IDCODE_INVALID.
//
// Note that this routine assumes that the TAP has been just reset and is in the Run-Test/Idle state.
// After a reset, all devices in the chain will have selected the IDCODE instruction, if supported,
// or the BYPASS instruction otherwise.

void jtag_enumerate_chain ( std::vector< uint32_t > * const discovered_id_codes )
{
  try
  {
    trace_jtag( "Enumerating the TAP chain...\n" );

    const unsigned MAX_DEVICE_COUNT = 1024;

    assert( discovered_id_codes->size() == 0 );

    uint32_t invalid_code = 0x7f;  // 7 bits with value '1'. Shift this out, we know we're done when we get it back.
    const unsigned int done_code = 0x3f;  // invalid_code is altered, we keep this for comparison (minus the start bit)

    jtag_write_bit(TMS); // SELECT_DR SCAN
    jtag_write_bit(  0); // CAPTURE_DR
    jtag_write_bit(  0); // SHIFT_DR

    // Putting a limit on the number of devices supported has the useful side effect
    // of ensuring we still exit in error cases (we never get the 0x7f manuf. id)

    bool at_least_one_non_zero_bit_read = false;

    while ( discovered_id_codes->size() < MAX_DEVICE_COUNT )
    {
      uint8_t start_bit = 0;

      // Get 1st bit: 0 = BYPASS, 1 = start of an IDCODE.
      jtag_read_write_bit( invalid_code & 0x01 ? TDO : 0, &start_bit );
      invalid_code >>= 1;

      if ( start_bit == 0 )
      {
        // printf( "The detected device does not support an IDCODE.\n" );
        discovered_id_codes->push_back( IDCODE_INVALID );
      }
      else
      {
        assert( start_bit == 1 );

        at_least_one_non_zero_bit_read = true;

        uint32_t temp_manuf_code;
        uint32_t temp_rest_code;

        // Get the 11-bit manufacturer code.
        jtag_read_write_stream( &invalid_code, &temp_manuf_code, IDCODE_MANUFACTURER_ID_BIT_COUNT, false );
        invalid_code >>= IDCODE_MANUFACTURER_ID_BIT_COUNT;

        if ( temp_manuf_code != done_code )
        {
          // Get 20 more bits with the rest of the IDCODE.
          jtag_read_write_stream( &invalid_code, &temp_rest_code, 20, false );
          invalid_code >>= 20;
          const uint32_t tempID = (temp_rest_code << (IDCODE_MANUFACTURER_ID_BIT_COUNT + 1)) | (temp_manuf_code << 1) | start_bit;

          // printf( "Device detected with an IDCODE of 0x%08X.\n", tempID );
          discovered_id_codes->push_back( tempID );
        }
        else
        {
          break;
        }
      }
    }

    if ( !at_least_one_non_zero_bit_read )
      throw std::runtime_error( "All data bits read back from the JTAG interface are zero, check that the JTAG interface is correctly connected." );

    if ( discovered_id_codes->size() == 0 )
      throw std::runtime_error( "Unable to detect any device on the JTAG chain." );

    if ( discovered_id_codes->size() >= MAX_DEVICE_COUNT )
      throw std::runtime_error( format_msg( "The JTAG chain seems to have more devices than the maximum allowed of %d, or, more likely, the JTAG interface is not correctly connected.", MAX_DEVICE_COUNT ) );

    // Put in IDLE mode.
    jtag_write_bit(TMS); // EXIT1_DR
    jtag_write_bit(TMS); // UPDATE_DR
    jtag_write_bit(0);   // IDLE

    trace_jtag( "Finished enumerating the TAP chain.\n" );
  }
  catch ( const std::exception & e )
  {
    throw std::runtime_error( format_msg( "Error enumerating the devices on the JTAG chain: %s",
                                          e.what() ) );
  }
}


void jtag_get_idcode ( const uint32_t cmd, uint32_t * const idcode )
{
  const bool saveconfig = is_altera_virtual_jtag;
  is_altera_virtual_jtag = false;  // We want the actual IDCODE, not the virtual device IDCODE.

  try
  {
    trace_jtag( "Writing the IDCODE instruction code...\n" );

    tap_set_ir( cmd );
    tap_move_from_idle_to_shift_dr();

    trace_jtag( "Reading the IDCODE value...\n" );

    jtag_discard_postfix_bits();

    uint32_t data_out = 0;
    jtag_read_write_stream( &data_out, idcode, 32, true );  // EXIT1_DR

    tap_move_from_exit_1_to_idle();

    trace_jtag( "Finished getting the IDCODE value.\n" );

    is_altera_virtual_jtag = saveconfig;
  }
  catch ( ... )
  {
    is_altera_virtual_jtag = saveconfig;
    throw;
  }
}
