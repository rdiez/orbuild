
#ifndef ASM_HELPERS_INC__ALREADY_INCLUDED
#define ASM_HELPERS_INC__ALREADY_INCLUDED


// ----------- Register definitions -----------

// The "jump and link" instructions store the return address in R9.
#define LINK_REGISTER_R9 r9

// These register definitions match the ABI.
#define ZERO_R0          r0
#define STACK_POINTER_R1 r1
#define FRAME_POINTER_R2 r2
#define RETURN_VALUE_R11 r11


// ----------- Load/move/clear helpers -----------

.macro LOAD_IMMEDIATE  reg, val
    l.movhi \reg,       hi( \val )
    l.ori   \reg, \reg, lo( \val )
.endm

.macro MOVE_REG  dest_reg, src_reg
    .ifnes "\dest_reg","\src_reg"
        l.ori \dest_reg, \src_reg, 0
    .endif
.endm

.macro CLEAR_REG reg
    l.movhi \reg, 0
.endm


.macro MOVE_FROM_SPR  reg, spr_reg
    l.mfspr \reg, ZERO_R0, \spr_reg
.endm

.macro MOVE_TO_SPR  spr_reg, reg
    l.mtspr ZERO_R0, \reg, \spr_reg
.endm


.macro SET_SPR_FLAGS spr_reg, flag_mask, scratch_reg_1, scratch_reg_2
    // We cannot use PUSH and POP here because some flags like Carry would get overwritten.

    // We could optimise this routine, as instruction l.mtspr already does a logical OR.
    MOVE_FROM_SPR \scratch_reg_2, \spr_reg
    LOAD_IMMEDIATE \scratch_reg_1, \flag_mask
    l.or    \scratch_reg_2, \scratch_reg_2, \scratch_reg_1
    MOVE_TO_SPR \spr_reg, \scratch_reg_2

.endm

.macro CLEAR_SPR_FLAGS spr_reg, flag_mask, scratch_reg_1, scratch_reg_2
    // We cannot use PUSH and POP here because some flags like Carry would get overwritten.

    MOVE_FROM_SPR \scratch_reg_2, \spr_reg
    LOAD_IMMEDIATE \scratch_reg_1, ~\flag_mask
    l.and   \scratch_reg_2, \scratch_reg_2, \scratch_reg_1
    MOVE_TO_SPR \spr_reg, \scratch_reg_2

.endm


.macro SET_SPR_SR_FLAGS flag_mask, scratch_reg_1, scratch_reg_2
    SET_SPR_FLAGS SPR_SR, \flag_mask, \scratch_reg_1, \scratch_reg_2
.endm

.macro CLEAR_SPR_SR_FLAGS flag_mask, scratch_reg_1, scratch_reg_2
    CLEAR_SPR_FLAGS SPR_SR, \flag_mask, \scratch_reg_1, \scratch_reg_2
    // We cannot use PUSH and POP here because some flags like Carry would get overwritten.
.endm


// ----------- Stack helpers -----------

// This value is defined in the OpenRISC 1000 specification.
#define EXCEPTION_STACK_SKIP_SIZE  2092


// WARNING: Functions without prolog cannot use these PUSH or POP macros.
// PERFORMANCE WARNING: These PUSH/POP macros are convenient, but can lead to slow code:
//                      if you need to PUSH or POP several registers, it's faster to
//                      use non-zero offsets when loading/storing and then increment/decrement
//                      the stack pointer just once.
// NOTE: There is a 2092-byte (see EXCEPTION_STACK_SKIP_SIZE) safety zone at the bottom of the stack,
//       check out the OpenRISC specification for more information.
.macro PUSH reg
    l.addi STACK_POINTER_R1, STACK_POINTER_R1, -4
    l.sw   0(STACK_POINTER_R1), \reg
.endm

// WARNING: see the warnings for PUSH.
.macro POP reg
    l.lwz  \reg, 0(STACK_POINTER_R1)
    l.addi STACK_POINTER_R1, STACK_POINTER_R1, 4
.endm


// ----------- l.nop definitions for simulation control and console output -----------


// Register definitions for the simulation l.nop codes.
#define NOP_REPORT_R3 r3
#define NOP_EXIT_R3   r3


// SEC = Simulation Exit Code
#define SEC_SUCCESS            0
#define SEC_RETURNED_FROM_MAIN 1
#define SEC_GENERIC_ERROR      2

// When running under the simulator, this l.nop code terminates the simulation.
.macro EXIT_SIMULATION_WITH_IMMEDIATE_EXIT_CODE immediate_value
    LOAD_IMMEDIATE NOP_EXIT_R3, \immediate_value
    l.nop 1
.endm

.macro EXIT_SIMULATION_WITH_REG_EXIT_CODE reg
    MOVE_REG NOP_EXIT_R3, \reg
    l.nop 1
.endm


// When running under the simulator, this l.nop code prints the value of R3 to the console.
.macro REPORT_TO_CONSOLE
    l.nop 2
.endm


// NOTE: The stack must be set up, as this macro uses PUSH and POP.
.macro REPORT_REG_TO_CONSOLE reg

    .ifeqs "\reg","r3"

        // Nothing more to do here, R3 is the register that gets printed.
        REPORT_TO_CONSOLE

    .else

        PUSH     NOP_REPORT_R3

        MOVE_REG NOP_REPORT_R3, \reg
        REPORT_TO_CONSOLE

        POP      NOP_REPORT_R3

    .endif

.endm


// NOTE: The stack must be set up, as this macro uses PUSH and POP.
.macro REPORT_IMMEDIATE_TO_CONSOLE val

    PUSH     NOP_REPORT_R3

    LOAD_IMMEDIATE NOP_REPORT_R3, \val
    REPORT_TO_CONSOLE

    POP      NOP_REPORT_R3

.endm


.macro PRINT_NEWLINE_TO_CONSOLE

    PUSH  r3

    LOAD_IMMEDIATE r3, 0x0A
    l.nop 4

    POP   r3

.endm


// If SR[F] is set, writes 0x00000001 to the console, otherwise it writes 0x00000000.

.macro REPORT_SRF_TO_CONSOLE

    l.bnf \@1$
    EMPTY_DELAY_SLOT

    REPORT_IMMEDIATE_TO_CONSOLE 0x00000001
    l.j \@2$
    EMPTY_DELAY_SLOT

\@1$:
    REPORT_IMMEDIATE_TO_CONSOLE 0x00000000

\@2$:

.endm


// If the given register is 0, writes 0x00000000 to the console, otherwise it writes 0x00000001.

.macro REPORT_BOOL_TO_CONSOLE  reg

  l.sfne \reg, ZERO_R0

  REPORT_SRF_TO_CONSOLE

.endm


// Writes to the console the value of the given register bit.

.macro REPORT_BIT_TO_CONSOLE  reg, single_bit_mask

    PUSH r2
    PUSH r3
    PUSH r4

    MOVE_REG r2, \reg

    LOAD_IMMEDIATE r4, \single_bit_mask
    l.and   r3, r2, r4

    REPORT_BOOL_TO_CONSOLE r3

    POP r4
    POP r3
    POP r2

.endm


// ----------- Jump helpers -----------

// Depending on the GCC compilation flags (-mcompat-delay, -mno-delay, -mdelay),
// one of the following symbols gets automatically defined.
// This code makes sure that one and only one of the those symbols is defined.

#if   defined(__OR1K_NODELAY__)
#  if defined(__OR1K_DELAY__) || defined(__OR1K_DELAY_COMPAT__)
#    error "Only one of __OR1K_NODELAY__, __OR1K_DELAY__ and __OR1K_DELAY_COMPAT__ must be defined."
#  endif
#elif defined(__OR1K_DELAY__)
#  if defined(__OR1K_NODELAY__) || defined(__OR1K_DELAY_COMPAT__)
#    error "Only one of __OR1K_NODELAY__, __OR1K_DELAY__ and __OR1K_DELAY_COMPAT__ must be defined."
#  endif
#elif defined(__OR1K_DELAY_COMPAT__)
#  if defined(__OR1K_DELAY__) || defined(__OR1K_NODELAY__)
#    error "Only one of __OR1K_NODELAY__, __OR1K_DELAY__ and __OR1K_DELAY_COMPAT__ must be defined."
#  endif
#else
#error "One of __OR1K_NODELAY__, __OR1K_DELAY__ or __OR1K_DELAY_COMPAT__ must be defined."
#endif


// The OR10 CPU has no jump delay slot. This macro helps write assembly code
// that is compatible with CPUs with and without jump delay slots,
// while still keeping the code easy to read and maintain.
// Some performance is wasted when targetting CPUs with a jump delay slot,
// see the OR10 readme file for more information and alternative macros.

.macro EMPTY_DELAY_SLOT

#if   defined(__OR1K_NODELAY__)
    // Issue no delay instruction, helps reduce the code size when targetting this platform.
#elif defined(__OR1K_DELAY__)
    // This wastes some performance when targetting this platform, but helps keep
    // the code easy to read and maintain.
    l.nop 0
#elif defined(__OR1K_DELAY_COMPAT__)
    l.nop 0
#else
#  error "One of __OR1K_NODELAY__, __OR1K_DELAY__ or __OR1K_DELAY_COMPAT__ must be defined."
#endif

.endm


// Other jump helpers.

.macro CALL overwritten_reg, subroutine_name
    LOAD_IMMEDIATE \overwritten_reg, \subroutine_name
    l.jalr  \overwritten_reg
    EMPTY_DELAY_SLOT
.endm

.macro RETURN_TO_LINK_REGISTER_R9
    l.jr LINK_REGISTER_R9
    EMPTY_DELAY_SLOT
.endm


// ----------- Clear the BSS section on start-up -----------

.macro CLEAR_BSS overwritten_reg1, overwritten_reg2

        LOAD_IMMEDIATE \overwritten_reg1, _bss_begin
        LOAD_IMMEDIATE \overwritten_reg2, _bss_end

        l.sfgeu \overwritten_reg1, \overwritten_reg2
        l.bf    bss_is_empty
        EMPTY_DELAY_SLOT

bss_clear_loop:
        // Possible optimisation to investigate: move "l.sw 0(\overwritten_reg1), r0" to the jump delay slot
        // as "l.sw -4(\overwritten_reg1), r0" or similar. But keep in mind that there are plans to remove
        // the jump delay slot.
        l.sw    0(\overwritten_reg1), r0
        l.addi  \overwritten_reg1, \overwritten_reg1, 4
        l.sfgtu \overwritten_reg2, \overwritten_reg1
        l.bf    bss_clear_loop
        EMPTY_DELAY_SLOT

bss_is_empty:

.endm


#endif  // Include this file only once.
