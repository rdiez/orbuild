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
  \@1$: .word  ( \opcode_value | (\dest_register_number << 11) )
        EMPTY_DELAY_SLOT

        // If the jump fails, we land here.
        REPORT_EXCEPTION \@1$

        l.j 52f
        EMPTY_DELAY_SLOT

        // If the jump succeeds, we land here.
    51: REPORT_IMMEDIATE_TO_CONSOLE 2
        
    52:

.endm
        

        STANDARD_TEST_ENVIRONMENT

        .section .exception_vectors

        // Alignment exception.
	    .org	0x600
alignment_exception:
        PUSH r2
        PUSH r3

        // Overwrite the exception-triggering instruction with an l.nop.
        // Note that this could cause cache-coherency issues between the instruction and the data caches.
        // Note also that this does not work properly if the instruction that triggered the exception
        // is in a jump delay slot.
        //
        // As an alternative we could increment the SPR_EPCR_BASE register by 4 before returning from the exception,
        // which would skip the instruction that triggered it.
        
        MOVE_FROM_SPR  r2, SPR_EPCR_BASE  // Address of the instruction that triggered the exception.
        LOAD_IMMEDIATE r3, 0x15000000     // Opcode for l.nop
        l.sw    0(r2), r3

        POP r3
        POP r2

        l.rfe


        // Illegal instruction exception.
        //
        // At the moment it behaves exactly like the alignment exception.
        // It would be best to differentiate, in order to make sure that the right exception gets triggered.
	    .org	0x700
        l.j alignment_exception
        EMPTY_DELAY_SLOT
        

        .section .text
start_tests:
        PUSH LINK_REGISTER_R9
        

        // Test l.jalr (jump and link register)

        TEST_JUMP 0x48000000, 5, 0
        TEST_JUMP 0x48000000, 5, 1
        TEST_JUMP 0x48000000, 5, 2
        TEST_JUMP 0x48000000, 5, 3
        
        // Test with link register (R9) as the destination.
        TEST_JUMP 0x48000000, 9, 0
        

        // Test l.jr (jump register)
        
        TEST_JUMP 0x44000000, 5, 0
        TEST_JUMP 0x44000000, 5, 1
        TEST_JUMP 0x44000000, 5, 2
        TEST_JUMP 0x44000000, 5, 3

        // Test with link register (R9) as the destination (OK here).
        TEST_JUMP 0x44000000, 9, 0


        POP LINK_REGISTER_R9
        RETURN_TO_LINK_REGISTER_R9
