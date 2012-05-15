/* Tests the jump instructions
 *
 * This is not a comprehensive test of any instruction (yet).
 * Of course what is really needed is a comprehensive instruction test...
 *
 * 
 * Copyright (C) 1999-2006 OpenCores
 *   Contributors various OpenCores participants
 * Copyright (C) 2010 Embecosm Limited
 *   Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
 * Copyright (C) 2012 R. Diez
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation; either version 3 of the License, or (at your option)
 * any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "TestHelpers.inc"


/* ----------------------------------------------------------------------------
 * Tests a jump instruction using a register destination.
 * Checks whether the jump succeeds, or whether an exception is triggered (but not if the right exception was triggered yet).
 *
 * We manually construct the opcode, to allow us to force R9 into the
 * destination field, to test exception handling. Usually the assembler would
 * prevent this.
 *
 * Do not specify R31 as the register to use for the jump, as it's used internally.
 * ------------------------------------------------------------------------- */

.macro TEST_JUMP  opcode_value  dest_register_number  alignment_offset

        REPORT_IMMEDIATE_TO_CONSOLE \opcode_value
        REPORT_IMMEDIATE_TO_CONSOLE \dest_register_number
        REPORT_IMMEDIATE_TO_CONSOLE \alignment_offset

        LOAD_IMMEDIATE r\dest_register_number, 51f + \alignment_offset

        // Clear the last exception address. Not really necessary.
        MOVE_TO_SPR  SPR_EPCR_BASE, ZERO_R0

        // Generate the jump opcode.
    50: .word  ( \opcode_value | (\dest_register_number << 11) )
        EMPTY_DELAY_SLOT

        // If the jump failed, we land here.
        REPORT_IMMEDIATE_TO_CONSOLE 1

        l.j 52f
        EMPTY_DELAY_SLOT

        // If the jump succeeds, we land here.
    51: REPORT_IMMEDIATE_TO_CONSOLE 0
        
    52:

.endm
        

        STANDARD_TEST_ENVIRONMENT


        .section .exception_vectors
        
        // Alignment exception.
	    .org	0x600
        // TODO: We need to patch the instruction here before returning, or we need to return
        //       to the next instruction. But beware that the or1200 implementation does not behave like the or1ksim simulator.
	    l.rfe
        

        .section .text
start_tests:
        PUSH LINK_REGISTER_R9
        

        // Test l.jalr (jump and link register)

        TEST_JUMP 0x48000000, 5, 0
        // TODO: some tests disabled, further work is needed
        // TEST_JUMP 0x48000000, 5, 1
        // TEST_JUMP 0x48000000, 5, 2
        // TEST_JUMP 0x48000000, 5, 3
        
        // Test with link register as the destination
        // TODO: disabled, need to add support for the ILLEGAL INSTRUCTION exception:
        // TEST_JUMP (0x48000000, 9, 0)
        

        // Test l.jr (jump register)
        
        TEST_JUMP 0x44000000, 5, 0
        // TODO: some tests disabled, further work is needed
        // TEST_JUMP 0x44000000, 5, 1
        // TEST_JUMP 0x44000000, 5, 2
        // TEST_JUMP 0x44000000, 5, 3

        // Test with link register as the destination (OK here)
        // TODO: disabled, need to add support for the ILLEGAL INSTRUCTION exception:
        // TEST_JUMP 0x44000000, 9, 0

        POP LINK_REGISTER_R9
        RETURN_TO_LINK_REGISTER_R9
