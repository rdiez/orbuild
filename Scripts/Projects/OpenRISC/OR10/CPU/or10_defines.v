
// Include this header file only once.
`ifndef or10_defines_included
`define or10_defines_included

`define OR10_ADDR_WIDTH     32
`define OR10_OPERAND_WIDTH  32

`define OR10_REG_NUMBER  4:0

`define OR10_PC_ADDR  `OR10_ADDR_WIDTH-1:2  // The last 2 bits of an (aligned) address are always zero.

// We cannot use function pc_addr_to_32() here because of a limitation in Verilator.
`define OR10_TRACE_PC_VAL  { cpureg_pc, 2'b00 }

// Fields inside the instruction opcode where the GPRs are.
`define OR10_IOP_GPR1  20:16
`define OR10_IOP_GPR2  15:11
`define OR10_IOP_DEST_GPR 25:21

`define OR10_IOP_PREFIX  31:26

// Bit ranges for a 16-bit Special Purpose Register (SPR) number.
`define OR10_SPR_GRP_NUMBER 15:11
`define OR10_SPR_REG_NUMBER 10:0


`endif  // Include this header file only once.
