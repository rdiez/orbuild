
#ifndef ASM_TEST_ENVIRONMENT_INC__ALREADY_INCLUDED
#define ASM_TEST_ENVIRONMENT_INC__ALREADY_INCLUDED

#include "SprDefs.inc"
#include "AsmHelpers.inc"


.macro STANDARD_TEST_HEADER

        // Without the "a" (allocatable) flag, this section gets some default flags,
        // and then it's discarded by objcopy when flattening to the binary file.
        // 'x' means executable.
        .section .exception_vectors, "ax"
        .org    0x100
        .global _start
    _start:
        // Clear R0 on start-up. There is no guarantee that R0 is hardwired to zero,
        // and indeed it is not when simulating the or1200 Verilog core.
        CLEAR_REG r0

        l.j test_startup
        EMPTY_DELAY_SLOT

        .section .text
      
    test_startup:

.endm


.macro STANDARD_TEST_BODY

        LOAD_IMMEDIATE STACK_POINTER_R1, stack_begin

        CLEAR_BSS r3, r4

        CALL r3, start_tests

        EXIT_SIMULATION_WITH_IMMEDIATE_EXIT_CODE SEC_SUCCESS

        .section .stack
        .space 4096  // We need more than EXCEPTION_STACK_SKIP_SIZE bytes.
    stack_begin:

.endm


.macro STANDARD_TEST_ENVIRONMENT

       // One of the test cases needs to do some tests before setting up the stack and so on.
       // That's the reason this macro is split into 2 parts, so that the caller
       // can inject code between the 2 initialisation phases.

       STANDARD_TEST_HEADER
       STANDARD_TEST_BODY

.endm


#endif  // Include this file only once.
