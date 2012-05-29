
#ifndef TEST_HELPERS_INC__ALREADY_INCLUDED
#define TEST_HELPERS_INC__ALREADY_INCLUDED

#include "AsmTestEnvironment.inc"


// Reports either 0x00000000 or 0x00000001.

.macro REPORT_EXCEPTION  instruction_addr

    PUSH r2
    PUSH r3

    MOVE_FROM_SPR r2, SPR_EPCR_BASE  // Save the exception address.

    LOAD_IMMEDIATE r3, \instruction_addr

    l.sfeq r2, r3

    l.bnf 55f
    EMPTY_DELAY_SLOT

    REPORT_IMMEDIATE_TO_CONSOLE 0x00000001
    l.j 56f
    EMPTY_DELAY_SLOT

 55:
    REPORT_IMMEDIATE_TO_CONSOLE 0x00000000

 56:
    POP r3
    POP r2

.endm


.macro TEST_INST_FF_I32_I32  flags_to_set, flags_to_clear, opcode, op1, op2

    LOAD_IMMEDIATE r5, \op1
    LOAD_IMMEDIATE r6, \op2

    REPORT_REG_TO_CONSOLE r5
    REPORT_REG_TO_CONSOLE r6

    // Clear the last exception address.
    MOVE_TO_SPR SPR_EPCR_BASE, ZERO_R0

    SET_SPR_SR_FLAGS   \flags_to_set  , r2, r3
    CLEAR_SPR_SR_FLAGS \flags_to_clear, r2, r3

\@1$: \opcode r4, r5, r6

    MOVE_FROM_SPR r2, SPR_SR         // Save the flags.

    REPORT_REG_TO_CONSOLE r4

    REPORT_BIT_TO_CONSOLE r2, SPR_SR_CY
    REPORT_BIT_TO_CONSOLE r2, SPR_SR_OV

    REPORT_EXCEPTION \@1$

    PRINT_NEWLINE_TO_CONSOLE
        
.endm


.macro TEST_INST_FF_I32_I16  flags_to_set, flags_to_clear, opcode, op1, op2

    LOAD_IMMEDIATE r5, \op1

    REPORT_REG_TO_CONSOLE r5
    REPORT_IMMEDIATE_TO_CONSOLE \op2
        
    SET_SPR_SR_FLAGS   \flags_to_set  , r2, r3
    CLEAR_SPR_SR_FLAGS \flags_to_clear, r2, r3

    // Clear the last exception address.
    MOVE_TO_SPR SPR_EPCR_BASE, ZERO_R0

\@1$: \opcode r4, r5, \op2

    MOVE_FROM_SPR r2, SPR_SR         // Save the flags.

    REPORT_REG_TO_CONSOLE r4

    REPORT_BIT_TO_CONSOLE r2, SPR_SR_CY
    REPORT_BIT_TO_CONSOLE r2, SPR_SR_OV

    REPORT_EXCEPTION \@1$

    PRINT_NEWLINE_TO_CONSOLE
        
.endm


.macro TEST_INST_I32_I32  opcode, op1, op2

  TEST_INST_FF_I32_I32 0, 0, \opcode, \op1, \op2

.endm

        
.macro TEST_INST_I32_I16  opcode, op1, op2

  TEST_INST_FF_I32_I16 0, 0, \opcode, \op1, \op2

.endm


.macro CHECK_CARRY_AND_OVERFLOW_NOT_SET  overwritten_reg1, overwritten_reg2

    MOVE_FROM_SPR \overwritten_reg1, SPR_SR

    LOAD_IMMEDIATE \overwritten_reg2, SPR_SR_CY + SPR_SR_OV
    l.and   \overwritten_reg1, \overwritten_reg1, \overwritten_reg2

    l.sfne \overwritten_reg1, ZERO_R0

    l.bnf \@1$
    EMPTY_DELAY_SLOT

    EXIT_SIMULATION_WITH_IMMEDIATE_EXIT_CODE  SEC_GENERIC_ERROR

  \@1$:

.endm

.macro SET_SR_FLAGS_FOR_RANGE_EXCEPTION overwritten_reg1, overwritten_reg2

    // When running under the or1ksim simulator, the range exception is triggered on a positive edge
    // (when the overflow flag changes from 0 to 1).
    // However, when running the or1200 Verilog code included with ORPSoC V2 under the Icarus Verilog simulator,
    // the exception is trigged on a level basis.
    // Therefore, we need to clear the OV (overflow) flag before setting the OVE (overflow exception) flag.

    CLEAR_SPR_SR_FLAGS SPR_SR_OV , \overwritten_reg1, \overwritten_reg2
    SET_SPR_SR_FLAGS   SPR_SR_OVE, \overwritten_reg1, \overwritten_reg2

.endm

#endif  // Include this file only once.
