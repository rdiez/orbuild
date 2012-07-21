/* Tests instruction l.sub
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


        STANDARD_TEST_ENVIRONMENT

        .section .exception_vectors

        // Range exception.  // TODO: common up this exception handler with the code in asm-add and so on.
        .org    0xb00

        // TODO: The stack safety zone is not taken into consideration.

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

        // When running under the or1ksim simulator, the range exception is triggered on a positive edge
        // (when the overflow flag changes from 0 to 1).
        // However, when running the or1200 Verilog code included with ORPSoC V2 under the Icarus Verilog simulator,
        // the exception is trigged on a level basis. As a result, as soon as l.rfe returns from the exception,
        // the range exception triggers again, causing an infinite loop.
        // Therefore, we need to clear the OVE (overflow exception) flag in the SPR_ESR_BASE register
        // before returning from the exception. We could clear the OV (overflow) flag instead,
        // but the test cases check that flag as part of the expected results.
        // This issue was discussed in the mailing list, see the following thread:
        //  "Different SPR_EPCR_BASE address on range exception with or1ksim and with or1200"
        //  http://lists.openrisc.net/pipermail/openrisc/2012-April/001052.html
        
        MOVE_FROM_SPR r2, SPR_ESR_BASE
        LOAD_IMMEDIATE r3, ~SPR_SR_OVE
        l.and  r2, r2, r3
        MOVE_TO_SPR SPR_ESR_BASE, r2
        
        POP r3
        POP r2

        l.rfe
        

        .section .text
start_tests:
        PUSH LINK_REGISTER_R9


        // ----------- Test l.sub -----------

        // Subtract two small positive numbers. Sets the carry, but never the overflow if the result is negative.
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0x00000003, 0x00000002
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0x00000001, 0x00000002

        // Check carry in is ignored.
        TEST_INST_FF_I32_I32 SPR_SR_CY, SPR_SR_OV, l.sub, 0x00000003, 0x00000002

        // Subtract two small negative numbers. Sets the carry flag if the
        // result is negative, but never the overflow flag.
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0xfffffffd, 0xfffffffe
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0xffffffff, 0xfffffffe

        // Subtract two quite large positive numbers. Should set neither the
        // overflow nor the carry flag.
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0x7fffffff, 0x3fffffff

        // Subtract two quite large negative numbers. Should set neither the overflow nor the carry flag.
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0x40000000, 0x40000000

        // Subtract two large positive numbers with a negative result. Should
        // set the carry, but not the overflow flag.
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0x3fffffff, 0x40000000

        // Subtract two large negative numbers with a positive result. Should
        // set neither the carry nor the overflow flag.
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0x40000000, 0x3fffffff

        // Subtract a large positive from a large negative number. Should set
        // overflow but not the carry flag.
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0x80000000, 0x7fffffff

        // Subtract a large negative from a large positive number. Should set
        // both the overflow and carry flags.
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0x7fffffff, 0x80000000


        // ------ Check that range exceptions are triggered.
        
        // Check that an overflow alone causes a RANGE Exception.
        SET_SR_FLAGS_FOR_RANGE_EXCEPTION r2, r3
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0x80000000, 0x7fffffff

        // Check that a carry alone does not cause a RANGE Exception.
        SET_SR_FLAGS_FOR_RANGE_EXCEPTION r2, r3
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0x3fffffff, 0x40000000

        // Check that carry and overflow together cause an exception.
        SET_SR_FLAGS_FOR_RANGE_EXCEPTION r2, r3
        TEST_INST_FF_I32_I32 0, SPR_SR_CY | SPR_SR_OV, l.sub, 0x7fffffff, 0x80000000
       
        CLEAR_SPR_SR_FLAGS SPR_SR_OVE, r2, r3

        POP LINK_REGISTER_R9
        RETURN_TO_LINK_REGISTER_R9
