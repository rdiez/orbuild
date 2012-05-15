/* Tests instructions l.and, l.andi
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

	    // Always set OVE. We should never trigger an exception, even if this bit is set.
        SET_SPR_SR_FLAGS SPR_SR_OVE, r2, r3

        // Test the l.and instruction with a range of operands.
        
	    TEST_INST_I32_I32 l.and, 0x00000000, 0x00000000
	    TEST_INST_I32_I32 l.and, 0xffffffff, 0xffffffff
	    TEST_INST_I32_I32 l.and, 0xaaaaaaaa, 0x00000000
	    TEST_INST_I32_I32 l.and, 0xaaaaaaaa, 0xaaaaaaaa
	    TEST_INST_I32_I32 l.and, 0x55555555, 0x00000000
	    TEST_INST_I32_I32 l.and, 0x55555555, 0x55555555
	    TEST_INST_I32_I32 l.and, 0xaaaaaaaa, 0x55555555
	    TEST_INST_I32_I32 l.and, 0x4c70f07c, 0xb38f0f83
	    TEST_INST_I32_I32 l.and, 0x4c70f07c, 0xc4c70f07
	    TEST_INST_I32_I32 l.and, 0xb38f0f83, 0x38f0f83b

        // Test the l.andi instruction with a range of operands.
        
	    TEST_INST_I32_I16 l.andi, 0x00000000, 0x0000
	    TEST_INST_I32_I16 l.andi, 0xffffffff, 0xffff
	    TEST_INST_I32_I16 l.andi, 0xaaaaaaaa, 0x0000
	    TEST_INST_I32_I16 l.andi, 0xaaaaaaaa, 0xaaaa
	    TEST_INST_I32_I16 l.andi, 0x55555555, 0x0000
	    TEST_INST_I32_I16 l.andi, 0x55555555, 0x5555
	    TEST_INST_I32_I16 l.andi, 0xaaaaaaaa, 0x5555
	    TEST_INST_I32_I16 l.andi, 0x4c70f07c, 0x0f83
	    TEST_INST_I32_I16 l.andi, 0x4c70f07c, 0x0f07
	    TEST_INST_I32_I16 l.andi, 0xb38f0f83, 0xf83b

        POP LINK_REGISTER_R9
        RETURN_TO_LINK_REGISTER_R9
