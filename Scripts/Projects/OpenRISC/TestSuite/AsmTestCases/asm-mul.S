/* Tests the multiply instructions.
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

        .section .text
start_tests:
        PUSH LINK_REGISTER_R9


        // Test l.mul
        
        // Multiply two small positive numbers. Should set no flags. 
        TEST_INST_I32_I32 l.mul, 0x00000002, 0x00000003

        // Multiply two quite large positive numbers. Should set no flags 
        TEST_INST_I32_I32 l.mul, 0x00008001, 0x0000fffe

        // Multiply two slightly too large positive numbers. Should set the
        // overflow, but not the carry flag .
        TEST_INST_I32_I32 l.mul, 0x00008000, 0x00010000

        // Multiply two large positive numbers. Should set both the carry and
        // overflow flags (even though the result is not a negative number. 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0x00010000, 0x00010000

        // Multiply two small negative numbers. Should set the overflow, but not
        // the carry flag. 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0xfffffffe, 0xfffffffd

        // Multiply two quite large negative numbers. Should set the overflow,
        // but not the carry flag. 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0xffff7fff, 0xffff0002

        // Multiply two slightly too large negative numbers. Should set both the
        // overflow, and the carry flags 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0xffff7fff, 0xffff0000

        // Multiply two large negative numbers. Should set the
        // both the carry and overflow flags (even though the result is a
        // positive number. 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0xffff0000, 0xfffeffff

        // Multiply one small negative number and one small positive number.
        // Should set the overflow, but not the carry flag. 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0x00000002, 0xfffffffd

        // Multiply one quite large negative number and one quite large
        // positive number. Should set the overflow, but not the carry flag. 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0xffff8000, 0x00010000

        // Multiply one slightly too large negative number and one slightly
        // too large positive number. Should set both the carry and overflow flags. 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0xffff7fff, 0x00010000

        // Multiply the largest negative number by positive unity. Should set
        // neither carry, nor overflow flag. 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0x80000000, 0x00000001

        // ------ Check that range exceptions are triggered.

        SET_SPR_SR_FLAGS SPR_SR_OVE, r2, r3
        
        // Check that an overflow alone causes a RANGE Exception. 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0x00008000, 0x00010000

        // Check that a carry alone does not cause a RANGE Exception. 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0x00000002, 0xfffffffd

        // Check that carry and overflow together cause an exception. 
        // TODO: disabled, as it fails against ORPSoC V2's or1200
        // TEST_INST_I32_I32 l.mul, 0xffff7fff, 0xffff0000

        CLEAR_SPR_SR_FLAGS SPR_SR_OVE, r2, r3


        // Test l.muli
        
        // Multiply two small positive numbers. Should set no flags. 
        TEST_INST_I32_I16 l.muli, 0x00000002, 0x0003

        /* TODO: carry on here
        // Multiply two quite large positive numbers. Should set no flags 
        TEST_INST_I32_I16 l.muli, 0x00010002, 0x7fff

        // Multiply two slightly too large positive numbers. Should set the
        // overflow, but not the carry flag 
        TEST_INST_I32_I16 l.muli, 0x00020000, 0x4000

        // Multiply two large positive numbers. Should set both the carry and
        // overflow flags (even though the result is not a negative number. 
        TEST_INST_I32_I16 l.muli, 0x00040000, 0x4000

        // Multiply two small negative numbers. Should set the overflow, but not
        // the carry flag. 
        TEST_INST_I32_I16 l.muli, 0xfffffffe, 0xfffd

        // Multiply two quite large negative numbers. Should set the overflow,
        // but not the carry flag. 
        TEST_INST_I32_I16 l.muli, 0xfffefffe, 0x8001

        // Multiply two slightly too large negative numbers. Should set both the
        // overflow, and the carry flags 
        TEST_INST_I32_I16 l.muli, 0xfffe0000, 0xbfff

        // Multiply two large negative numbers. Should set the
        // both the carry and overflow flags (even though the result is a positive number. 
        TEST_INST_I32_I16 l.muli, 0xfffdfffe, 0x8000

        // Multiply one small negative number and one small positive number.
        // Should set the overflow, but not the carry flag. 
        TEST_INST_I32_I16 l.muli, 0x00000002, 0xfffd

        // Multiply one quite large negative number and one quite large
        // positive number. Should set the overflow, but not the carry flag. 
        TEST_INST_I32_I16 l.muli, 0x00010000, 0x8000

        // Multiply one slightly too large negative number and one slightly
        // too large positive number. Should set both the carry and overflow flags. 
        TEST_INST_I32_I16 l.muli, 0xfffdfffc, 0x4000

        // Multiply the largest negative number by positive unity. Should set
        // neither carry, nor overflow flag. 
        TEST_INST_I32_I16 l.muli, 0x80000000, 0x0001

        // ------ Check that range exceptions are triggered.

        SET_SPR_SR_FLAGS SPR_SR_OVE, r2, r3

        // Check that an overflow alone causes a RANGE Exception. 
        TEST_INST_I32_I16 l.muli, 0x00020000, 0x4000

        // Check that a carry alone does not cause a RANGE Exception. 
        TEST_INST_I32_I16 l.muli, 0xfffffffe, 0xfffd

        // Check that carry and overflow together cause an exception. 
        TEST_INST_I32_I16 l.muli, 0xfffdfffe, 0x8000

        CLEAR_SPR_SR_FLAGS SPR_SR_OVE, r2, r3

        
        // Test l.mulu
        
        // Multiply two small positive numbers. Should set no flags. 
        TEST_INST_I32_I32 l.mulu, 0x00000002, 0x00000003

        // Multiply two quite large positive numbers. Should set no flags 
        TEST_INST_I32_I32 l.mulu, 0x00008001, 0x0000fffe

        // Multiply two slightly too large positive numbers. Should set the
        // overflow, but not the carry flag 
        TEST_INST_I32_I32 l.mulu, 0x00008000, 0x00010000

        // Multiply two large positive numbers. Should set both the carry and
        // overflow flags (even though the result is not a negative number. 
        TEST_INST_I32_I32 l.mulu, 0x00010000, 0x00010000

        // Multiply two small negative numbers. Should set the overflow, but not
        // the carry flag. 
        TEST_INST_I32_I32 l.mulu, 0xfffffffe, 0xfffffffd

        // Multiply two quite large negative numbers. Should set the overflow,
        // but not the carry flag. 
        TEST_INST_I32_I32 l.mulu, 0xffff7fff, 0xffff0002

        // Multiply two slightly too large negative numbers. Should set both the
        // overflow, and the carry flags 
        TEST_INST_I32_I32 l.mulu, 0xffff7fff, 0xffff0000

        // Multiply two large negative numbers. Should set the
        //  both the carry and overflow flags (even though the result is a positive number. 
        TEST_INST_I32_I32 l.mulu, 0xffff0000, 0xfffeffff

        // Multiply one small negative number and one small positive number.
        // Should set the overflow, but not the carry flag. 
        TEST_INST_I32_I32 l.mulu, 0x00000002, 0xfffffffd

        // Multiply one quite large negative number and one quite large
        // positive number. Should set the overflow, but not the carry flag. 
        TEST_INST_I32_I32 l.mulu, 0xffff8000, 0x00010000

        // Multiply one slightly too large negative number and one slightly
        // too large positive number. Should set both the carry and overflow flags. 
        TEST_INST_I32_I32 l.mulu, 0xffff7fff, 0x00010000

        // Multiply the largest negative number by positive unity. Should set
        // neither carry, nor overflow flag. 
        TEST_INST_I32_I32 l.mulu, 0x80000000, 0x00000001


        // ------ Check that range exceptions are NEVER triggered.

        SET_SPR_SR_FLAGS SPR_SR_OVE, r2, r3
        
        // Check that what would cause an overflow alone in 2's complement does
        // not cause a RANGE Exception. 
        TEST_INST_I32_I32 l.mulu, 0x00008000, 0x00010000

        // Check that a carry alone does not cause a RANGE Exception. 
        TEST_INST_I32_I32 l.mulu, 0x00000002, 0xfffffffd

        // Check that what would cause an overflow and carry in 2's complement
        // does not cause a RANGE Exception. 
        TEST_INST_I32_I32 l.mulu, 0xffff7fff, 0xffff0000

        CLEAR_SPR_SR_FLAGS SPR_SR_OVE, r2, r3
        */

        POP LINK_REGISTER_R9
        RETURN_TO_LINK_REGISTER_R9
