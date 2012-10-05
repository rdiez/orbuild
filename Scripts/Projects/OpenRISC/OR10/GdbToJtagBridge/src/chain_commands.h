#ifndef _CHAIN_COMMANDS_H_
#define _CHAIN_COMMANDS_H_

#include <stdint.h>

#include <vector>

#include <cable_drivers/cable_write_bit_constants.h>  // Needed by jtag_write_bit().

// Functions to configure the JTAG chain.
void config_set_IR_size(int size);
void config_set_IR_prefix_bits(int bits);
void config_set_IR_postfix_bits(int bits);
void config_set_DR_prefix_bits(int bits);
void config_set_DR_postfix_bits(int bits);
void config_set_debug_cmd(unsigned int cmd);
void config_set_alt_vjtag(unsigned char enable);
void config_set_vjtag_cmd_vir(unsigned int cmd);
void config_set_vjtag_cmd_vdr(unsigned int cmd);
void config_set_xilinx_bscan_internal_jtag ( bool enable );


// ----------- High-level TAP operations -----------

#define IDCODE_MANUFACTURER_ID_BIT_COUNT 11
#define IDCODE_MANUFACTURER_ID_MASK ( ( 1 << IDCODE_MANUFACTURER_ID_BIT_COUNT ) - 1 )

void tap_reset ( void );
void jtag_enumerate_chain ( std::vector< uint32_t > * discovered_id_codes );
void jtag_get_idcode ( uint32_t cmd, uint32_t * idcode );
void set_ir_to_cpu_debug_module ( void );

// After a TAP operation we normally return to the IDLE state.
// We could optimise a little further and always remain in the DR chain,
// because we only set the IR register on start-up.
void tap_set_ir ( unsigned instruction_opcode );
void tap_move_from_idle_to_shift_dr ( void );
void tap_move_from_exit_1_to_idle ( void );


// ----------- Low-level TAP operations -----------

// Thin wrappers so that other files do not need to include cable_api.h .
// All JTAG protocol traffic goes through this include file alone,
// this simplifies the system somewhat.
// void jtag_write_bit      ( uint8_t packet );
void jtag_read_write_bit ( uint8_t packet, uint8_t * in_bit );

// Functions to Send/receive bitstreams via JTAG.
// These functions are aware of other devices in the chain, and may adjust for them.
void jtag_write_stream ( const uint32_t * out_data,
                         int length_bits,
                         bool set_TMS_during_the_last_bit_transfer );
void jtag_read_write_stream ( const uint32_t * out_data,
                              uint32_t *in_data,
                              int length_bits,
                              bool set_TMS_during_the_last_bit_transfer );

void jtag_discard_postfix_bits ( void );
void jtag_shift_by_prefix_bits_with_ending_tms ( int extra_bit_count );

#endif
