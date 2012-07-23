/* Tests instructions l.mfspr and l.mtspr
 *
 * This version does not use the MAC support, and is therefore suitable
 * for CPU implementations without built-in support for those instructions.
 *
 * The version that uses the MAC instructions tests a little better,
 * because it can conveniently read and write to the MAC_LO SPR without using the
 * l.mfspr and l.mtspr instructions, therefore that test version still exists
 * in a separate file for CPUs which do support MAC instructions.
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

#include "AsmTestEnvironment.inc"

#define TEST_VAL 0xdeadbeef
        

/* ----------------------------------------------------------------------------
 * A macro to carry out a test of l.mfspr
 *
 * Special Register EEAR (0x0030) is used as the test SPR, so spr_number and immediate_val_to_or
 * should be chosen to address this register.
 *
 * The value placed in the register is entirely arbitrary - we use 0xdeadbeef.
 * ------------------------------------------------------------------------- */

.macro TEST_MFSPR  spr_number, immediate_val_to_or

    REPORT_IMMEDIATE_TO_CONSOLE \spr_number
    REPORT_IMMEDIATE_TO_CONSOLE \immediate_val_to_or

    // Write TEST_VAL to SPR_EEAR_BASE.
    LOAD_IMMEDIATE r2, TEST_VAL
    MOVE_TO_SPR SPR_EEAR_BASE, r2

    LOAD_IMMEDIATE r5, \spr_number

    l.mfspr r4, r5, \immediate_val_to_or

    REPORT_REG_TO_CONSOLE r4

    PRINT_NEWLINE_TO_CONSOLE        

.endm

    
/* ----------------------------------------------------------------------------
 * A macro to carry out a test of l.mtspr
 *
 * Special Register EEAR (0x0030) is used as the test SPR, so spr_number and immediate_val_to_or
 * should be chosen to address this register.
 *
 * The value placed in the register is entirely arbitrary - we use 0xdeadbeef.
 * ------------------------------------------------------------------------- */

.macro TEST_MTSPR  spr_number, immediate_val_to_or

    REPORT_IMMEDIATE_TO_CONSOLE \spr_number
    REPORT_IMMEDIATE_TO_CONSOLE \immediate_val_to_or

    // Clear SPR_EEAR_BASE.
    MOVE_TO_SPR SPR_EEAR_BASE, ZERO_R0

    LOAD_IMMEDIATE r4, TEST_VAL
    LOAD_IMMEDIATE r5, \spr_number

    l.mtspr r5, r4, \immediate_val_to_or

    // Retrieve SPR_EEAR_BASE.
    MOVE_FROM_SPR r4, SPR_EEAR_BASE
    REPORT_REG_TO_CONSOLE r4

    PRINT_NEWLINE_TO_CONSOLE
        
.endm
        

        STANDARD_TEST_ENVIRONMENT

        .section .text
start_tests:
        PUSH LINK_REGISTER_R9


        // Test the l.mfspr instruction with a range of operands.

        // Move a test value using zero in the register
        TEST_MFSPR SPR_VR, SPR_EEAR_BASE  // 0x0000, 0x0030

        // Move a test value using zero as the constant
        TEST_MFSPR SPR_EEAR_BASE, SPR_VR  // 0x0030, 0x0000

        // Move a test value using non-zero in both register and constant.
        // Some of these values will not give the correct result if OR rather
        // than ADD is used to determine the SPR address
        TEST_MFSPR SPR_EEAR_BASE, SPR_EEAR_BASE  // 0x0030, 0x0030
        TEST_MFSPR 0x0020, 0x0010
        TEST_MFSPR 0x0010, 0x0020
        TEST_MFSPR SPR_EEAR_BASE,  0x0020
        TEST_MFSPR 0x0010, SPR_EEAR_BASE


        // Test the l.mtspr instruction with a range of operands.
        
        // Move a test value using zero in the register
        TEST_MTSPR SPR_VR, SPR_EEAR_BASE  // 0x0000, 0x0030

        // Move a test value using zero as the constant
        TEST_MTSPR SPR_EEAR_BASE, SPR_VR  // 0x0030, 0x0000

        // Move a test value using non-zero in both register and constant.
        // Some of these values will not give the correct result if OR rather
        // than ADD is used to determine the SPR address
        TEST_MTSPR SPR_EEAR_BASE, SPR_EEAR_BASE  // 0x0030, 0x0030
        TEST_MTSPR 0x0020, 0x0010
        TEST_MTSPR 0x0010, 0x0020
        TEST_MTSPR SPR_EEAR_BASE,  0x0020
        TEST_MTSPR 0x0010, SPR_EEAR_BASE

        POP LINK_REGISTER_R9
        RETURN_TO_LINK_REGISTER_R9
