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

        #include "RangeExceptionHandler.inc"


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
