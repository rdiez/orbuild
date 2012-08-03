/* Tests the Tick Timer unit.
 *
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


#define TIMER_MODE_STOP         (0 << 30)
#define TIMER_MODE_RESTART      (1 << 30)
#define TIMER_MODE_SINGLE_SHOT  (2 << 30)
#define TIMER_MODE_CONTINUE     (3 << 30)

#define MAX_TARGET_TICK_COUNT 0xFFFFFFF  // Beware, that's 7 F's, and not 8 of them.


.macro WAIT_TIME loop_iterations, scratch_reg_1, scratch_reg_2
        
        LOAD_IMMEDIATE \scratch_reg_1, \loop_iterations
        LOAD_IMMEDIATE \scratch_reg_2, 1

\@1$:        
        l.sub \scratch_reg_1, \scratch_reg_1, \scratch_reg_2
        l.sfeq \scratch_reg_1, ZERO_R0

        l.bnf \@1$
        EMPTY_DELAY_SLOT

.endm
        

        STANDARD_TEST_ENVIRONMENT

        .section .exception_vectors
        
        // Tick Timer exception.
        .org    0x500

        l.addi r6, r6, 1
        REPORT_REG_TO_CONSOLE r6

        // Clear the Tick Timer Interrupt Enable flag.
        // Otherwise, the Interrupt Pending flag may trigger again.
        CLEAR_SPR_FLAGS SPR_TTMR, SPR_TTMR_IE, r10, r11

        // Clear the Tick Timer Interrupt Pending flag.
        CLEAR_SPR_FLAGS SPR_TTMR, SPR_TTMR_IP, r10, r11

        l.rfe


        .section .text
start_tests:
        PUSH LINK_REGISTER_R9


        CLEAR_REG r6
        REPORT_REG_TO_CONSOLE r6  // report(0x00000000);

        MOVE_TO_SPR SPR_TTMR, ZERO_R0
        MOVE_TO_SPR SPR_TTCR, ZERO_R0

        // Enable Tick Timer Exceptions.
        SET_SPR_FLAGS SPR_SR, SPR_SR_TEE, r2, r3
        
        // Set the Tick Timer Interrupt Enable flag.
        // This alone should trigger an exception, as the counter and the target match (they are both 0),
        // and print report(0x00000001);
        SET_SPR_FLAGS SPR_TTMR, SPR_TTMR_IE, r2, r3


        // Test a single shot from the current value of 0 to a target of 4;
        LOAD_IMMEDIATE r3, TIMER_MODE_SINGLE_SHOT | SPR_TTMR_IE | 4
        MOVE_TO_SPR SPR_TTMR, r3

        // Wait for the timer to trigger, at some point it should print report(0x00000004);
        l.nop 0
        l.nop 0
        l.nop 0
        l.nop 0
        l.nop 0
        
        // The counter should have stopped at 4, the value printed should be report(0x00000004);
        MOVE_FROM_SPR r3, SPR_TTCR
        REPORT_REG_TO_CONSOLE r3


        // Set the timer to restart, it should trigger once more.
        LOAD_IMMEDIATE r3, TIMER_MODE_SINGLE_SHOT | SPR_TTMR_IE | 4
        MOVE_TO_SPR SPR_TTMR, r3

        // Wait for the timer to trigger, at some point it should print report(0x00000003);
        l.nop 0
        l.nop 0
        l.nop 0
        l.nop 0
        l.nop 0


        // Stop the Tick Timer and disable its interrupt.
        LOAD_IMMEDIATE r2, TIMER_MODE_STOP
        MOVE_TO_SPR SPR_TTMR, r2

        // Set a higher target value. The counter will wrap-around and trigger the exception, but it'll take some time.

        #define CLOCK_TICK_COUNT 30   // This amount of clock cycles should be OK for most CPU implementations

        LOAD_IMMEDIATE NOP_REPORT_R3, 0xAAAAAAAA

        LOAD_IMMEDIATE r2, 0xFFFFFFFF - 100 - CLOCK_TICK_COUNT  // 0xFFFFFFFF is not the same as MAX_TARGET_TICK_COUNT, which has 4 bits less.
        MOVE_TO_SPR SPR_TTCR, r2
        
        LOAD_IMMEDIATE r2, TIMER_MODE_CONTINUE | SPR_TTMR_IE | MAX_TARGET_TICK_COUNT - 100
        MOVE_TO_SPR SPR_TTMR, r2

        // Wait some time.
        l.nop 0
        l.nop 0
        l.nop 0
        l.nop 0
        l.nop 0

        // Print "report(0xaaaaaaaa);", the timer should not have triggered yet.
        REPORT_TO_CONSOLE

        // Wait longer, at some point it should print report(0x00000004);
        // Note that this makes OR1200 hang (as of Juni 2012, ORPSoC simulation). I suspect
        // the l.sub instruction used by WAIT_TIME is broken at the moment.
        WAIT_TIME 20, r3, r4

        // Print "report(0xbbbbbbbb);", it should come after the "report(0x00000004);"
        REPORT_IMMEDIATE_TO_CONSOLE 0xBBBBBBBB
        
        // Note that we could write some more tests here, we have tested just the most basic tick timer features.
        // For example, we haven't tested yet that TIMER_MODE_CONTINUE does continue.

        
        POP LINK_REGISTER_R9
        RETURN_TO_LINK_REGISTER_R9
