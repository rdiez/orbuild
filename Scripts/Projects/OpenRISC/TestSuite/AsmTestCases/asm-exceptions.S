
/* Tests some CPU exceptions.

   Copyright (C) 2012, R. Diez

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License version 3
   as published by the Free Software Foundation.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License version 3 for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "TestHelpers.inc"


        STANDARD_TEST_ENVIRONMENT

        .section .exception_vectors

        // Alignment exception.
	    .org	0x600
        REPORT_IMMEDIATE_TO_CONSOLE 0x600
        l.j overwrite_exception_instruction
        EMPTY_DELAY_SLOT

        // Illegal instruction exception.
	    .org	0x700
        REPORT_IMMEDIATE_TO_CONSOLE 0x700
        l.j overwrite_exception_instruction
        EMPTY_DELAY_SLOT

        // Range exception.
	    .org	0xB00
        REPORT_IMMEDIATE_TO_CONSOLE 0xB00
        l.j overwrite_exception_instruction
        EMPTY_DELAY_SLOT

        // l.sys exception.
	    .org	0xC00
        REPORT_IMMEDIATE_TO_CONSOLE 0xC00
        l.j overwrite_exception_instruction
        EMPTY_DELAY_SLOT

        // l.trap exception.
	    .org	0xE00
        REPORT_IMMEDIATE_TO_CONSOLE 0xE00
        l.j overwrite_exception_instruction
        EMPTY_DELAY_SLOT

overwrite_exception_instruction:
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


        .section .text
start_tests:
        PUSH LINK_REGISTER_R9


        // Illegal instruction opcode.
        .word  0x10 << 26

        l.sys 0


        // This bit is always one in the Supervisor Register, so it should trigger a trap.
        #define FO_FLAG_BIT 15
        l.trap FO_FLAG_BIT

        // Clear the OV flag, so that it does not trigger a trap.
        #define OV_FLAG_BIT 11
        CLEAR_SPR_SR_FLAGS OV_FLAG_BIT, r2, r3
        l.trap OV_FLAG_BIT


        POP LINK_REGISTER_R9
        RETURN_TO_LINK_REGISTER_R9
