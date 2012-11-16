#ifndef _DBG_API_H_
#define _DBG_API_H_

#include <stdint.h>

#include <vector>

// The xxx_e() versions throw an exception on error.

void dgb_enable_jtag_trace ( bool enable_jtag_trace );

bool dbg_cpu0_read_spr    ( uint16_t cpu_spr_reg_number, uint32_t * cpu_spr_reg_value );
void dbg_cpu0_read_spr_e  ( uint16_t cpu_spr_reg_number, uint32_t * cpu_spr_reg_value );

bool dbg_cpu0_write_spr   ( uint16_t cpu_spr_reg_number, uint32_t   cpu_spr_reg_value );
void dbg_cpu0_write_spr_e ( uint16_t cpu_spr_reg_number, uint32_t   cpu_spr_reg_value );

void dbg_cpu0_read_mem  ( uint32_t start_addr, uint32_t byte_count,       std::vector< uint8_t > * data_read     );
bool dbg_cpu0_write_mem ( uint32_t start_addr, uint32_t byte_count, const std::vector< uint8_t > * data_to_write );

bool dbg_cpu0_is_stalled ( void );

#endif
