
// Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

// This start-up code is for test cases writen in C.
        
#include "AsmTestEnvironment.inc"

        STANDARD_TEST_HEADER

        LOAD_IMMEDIATE STACK_POINTER_R1, stack_begin

        CLEAR_BSS r3, r4

        // Call main() with argc = argv = envp = 0
        CLEAR_REG r3
        CLEAR_REG r4
        CLEAR_REG r5
        CALL r6, main

        EXIT_SIMULATION_WITH_REG_EXIT_CODE RETURN_VALUE_R11

        .section .stack
        .space 4096  // We need more than EXCEPTION_STACK_SKIP_SIZE bytes.
stack_begin:

