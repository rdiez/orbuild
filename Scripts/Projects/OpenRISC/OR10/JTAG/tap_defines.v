
// This is similar to the IDCODE that the or1200 CPU uses,
// only the new part number (IQ) is the or1200's value + 100 (decimal).
`define OPENRISC_CPU_JTAG_IDCODE_VALUE  32'h149B51C3  // or1200 uses 32'h149511c3.
  // 0001             bits [31:28], version
  // 0100100110110101 bits [27:12], part number (IQ), 0100100101010001 + 100 (decimal)
  // 00011100001      bits [11: 1], manufacturer id (flextronics)
  // 1                bit 0, always "1" as required by the JTAG standard


// JTAG Instructions. The Instruction Register is 4 bits long at the moment,
// but 3 bits would do. However, this optimisation is probably not worth the trouble.
`define JTAG_INSTRUCTION_EXTEST          4'b0000  // Not supported at the moment.
`define JTAG_INSTRUCTION_SAMPLE_PRELOAD  4'b0001  // Not supported at the moment.
`define JTAG_INSTRUCTION_IDCODE          4'b0010  // Supported.
// The following command is specific to OR10. Because the Xilinx TAP primitives have just 1 or 2 user-defined
// JTAG instructions, all OR10 debug operations is performed with a single DEBUG instruction,
// which can be mapped to one of Xilinx' user-defined instructions when using that interface.
// If it weren't for this limitation, it would have been more comfortable to define
// several JTAG instructions for the different types of OR10 debug operations.
`define JTAG_INSTRUCTION_DEBUG           4'b1000  // Specific to OR10, see comment above.
`define JTAG_INSTRUCTION_MBIST           4'b1001  // Not supported at the moment.
`define JTAG_INSTRUCTION_BYPASS          4'b1111  // Supported. According to the JTAG specification, the BYPASS instruction opcode must be all 1's.
