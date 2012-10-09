/* Tests the divide instructions.
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


        // Test l.div

	    // Divide two positive numbers and check rounding. Should set no flags. 
        TEST_INST_I32_I32 l.div, 0x0000000c, 0x00000003  // 12 / 3 = 4
	    TEST_INST_I32_I32 l.div, 0x0000000b, 0x00000003  // 11 / 3 = 3
        
	    // Divide two negative numbers and check rounding. Should set no flags. 
	    TEST_INST_I32_I32 l.div, 0xfffffff4, 0xfffffffd
	    TEST_INST_I32_I32 l.div, 0xfffffff5, 0xfffffffd

	    // Divide a negative number by a positive number and check rounding. Should set no flags. 
	    TEST_INST_I32_I32 l.div, 0xfffffff4, 0x00000003
	    TEST_INST_I32_I32 l.div, 0xfffffff5, 0x00000003

	    // Divide a positive number by a negative number and check rounding. Should set no flags. 
	    TEST_INST_I32_I32 l.div, 0x0000000c, 0xfffffffd
	    TEST_INST_I32_I32 l.div, 0x0000000b, 0xfffffffd

	    // Divide by zero. Should set the carry flag.
        LOAD_IMMEDIATE r4, 0x12345678
	    TEST_INST_I32_I32 l.div, 0x0000000c, 0x00000000
        LOAD_IMMEDIATE r4, 0xABCDEF01
	    TEST_INST_I32_I32 l.div, 0xfffffff4, 0x00000000

	    // Divide by zero, should raise exception.
        SET_SR_FLAGS_FOR_RANGE_EXCEPTION r2, r3
        LOAD_IMMEDIATE r4, 0x12345678
	    TEST_INST_I32_I32 l.div, 0x0000000c, 0x00000000

        SET_SR_FLAGS_FOR_RANGE_EXCEPTION r2, r3
        LOAD_IMMEDIATE r4, 0xABCDEF01
	    TEST_INST_I32_I32 l.div, 0xfffffff4, 0x00000000

        CLEAR_SPR_SR_FLAGS SPR_SR_OVE, r2, r3


        // Test l.divu
       
	    // Divide two positive numbers and check rounding. Should set no flags. 
	    TEST_INST_I32_I32 l.divu, 0x0000000c, 0x00000003
	    TEST_INST_I32_I32 l.divu, 0x0000000b, 0x00000003

	    // Divide two numbers that would be negative under 2's complement and
	    // check rounding. Should set no flags. 
	    TEST_INST_I32_I32 l.divu, 0xfffffff4, 0xfffffffd
	    TEST_INST_I32_I32 l.divu, 0xfffffff5, 0xfffffffd

	    // Divide a number that would be negative under 2's complement by a
	    // number that would be positive under 2's complement and check rounding. Should set no flags. 
	    TEST_INST_I32_I32 l.divu, 0xfffffff4, 0x00000003
	    TEST_INST_I32_I32 l.divu, 0xfffffff5, 0x00000003

	    // Divide a number that would be positive under 2's complement by a
	    // number that would be negative under 2's complement and check rounding. Should set no flags. 
	    TEST_INST_I32_I32 l.divu, 0x0000000c, 0xfffffffd
	    TEST_INST_I32_I32 l.divu, 0x0000000b, 0xfffffffd

	    // Divide by zero. Should set the carry flag. 
        LOAD_IMMEDIATE r4, 0x12345678
	    TEST_INST_I32_I32 l.divu, 0x0000000c, 0x00000000
        LOAD_IMMEDIATE r4, 0xABCDEF01
		TEST_INST_I32_I32 l.divu, 0xfffffff4, 0x00000000

        // Divide by zero, should raise exception.
        SET_SR_FLAGS_FOR_RANGE_EXCEPTION r2, r3
        LOAD_IMMEDIATE r4, 0x12345678
	    TEST_INST_I32_I32 l.divu, 0x0000000c, 0x00000000

		SET_SR_FLAGS_FOR_RANGE_EXCEPTION r2, r3
        LOAD_IMMEDIATE r4, 0xABCDEF01
        TEST_INST_I32_I32 l.divu, 0xfffffff4, 0x00000000

        CLEAR_SPR_SR_FLAGS SPR_SR_OVE, r2, r3


        POP LINK_REGISTER_R9
        RETURN_TO_LINK_REGISTER_R9
