
/* GPR register file for the OR10 CPU.

   My first OR10 implementation did not use a register file for the CPU's general purpose registers (GPRs),
   I just declared the GPRs like this and let the Verilog code read from and write to them as needed:

     reg [31:0] cpureg_gprs[31:0];

   Xilinx' ISE version 13.4 inferred then 1,371 multiplexers and wanted to use
   31,463 slice LUTs, which is more than 3 times as many as my FPGA had.

   It turns out that the standard FPGA structure is not suitable to model register files that way.
   In order to conserve FPGA resources, you need to place the CPU GPRs in a built-in FPGA memory block,
   and address them as if they were memory locations.

   There are 2 types of memories in Xilinx FPGAs: Distributed Memory and Block Memory.
   Using Block Memory would waste quite a lot of storage bits (as Xilinx block memories tend to be much bigger
   than the required 32x32=1024 bits) but would save LUTs. In any case,
   a Block Memory would slow the OR10 CPU down, as it only supports synchronised reads, which means
   2 clock cycles per read: on the 1st clock cycle, you write the GPR number (the memory address),
   and on the 2nd clock cycle you can read the GPR data. With Distributed Memory, the OR10 CPU
   can use asynchronous reads and integrate the GPR read access time into the instruction fetch time.

   Let's consider the following OpenRISC OR32 instruction:

     l.sll r1, r2, r3   # Logical Shift Left.

   This instruction needs to read from GRPs R2 and R3, and write to R1.

   On the first clock posedge, the CPU issues a Wishbone instruction fetch (read) operation
   for the l.sll instruction and then starts waiting for the Wishbone fetch to complete.
   Let's assume for a moment that the fetch completes on the second clock posedge.
   The Wishbone read data output also feeds the register file's address lines over
   a combinatorial path, and the register file reads asynchronously, so, in the same fetch
   clock cycle, the register file reads the GPR addresses 2 and 3 (for R2 and R3)
   from the instruction opcode data read over the Wishbone bus and presents the data in R2 and R3.

   That means that the synthesiser will integrate the GPR read time with the
   overall instruction fetch time. Therefore, when the execution phase starts on the
   second clock posedge, it can latch both the instruction opcode and the contents of R2 and R3.

   Note that the register file does not have a "read enable" signal, so it is always reading some GPR,
   whether necessary or not. ORBIS32 instructions tend to place their 1st and 2nd source GPRs
   at the same locations, but some instructions use those bits for other purposes. Furthermore,
   the Wishbone fetch may take more than 1 clock cycle to complete, so the second clock posedge
   may not have delivered any data yet. In all those cases, the register file will be reading
   the value of some random GPR, but that's OK.

   In fact, we only need to read GPRs during the instruction execute phase, and write CPU GPRs
   after execution (at the beginning of the fetch phase for the next instruction, see below).
   There is a write-enable signal, so that writes are only issued as needed, but the register file
   always reads some GPR on each clock cycle. The combinatorial path between the Wishbone read output
   and the register file's address lines could be enhanced in order to stop reading GPRs when
   the read results are not necessary. However, this logic is not necessary, as the GPR values read
   will be ignored if not needed.

   In the example above, the CPU can simultaneously read from R2 and R3, because the register file
   has been implemented as dual-port memory (with 2 read ports). The current OR10 implementation
   is not pipelined, so it does not need to read and write at the same time, therefore 1 of the 2 ports
   can be shared for read/write operations. Otherwise, we would need 3 ports, 2 read ports and 1 write port.

   When reading, the CPU will always be using the GRP numbers specified in the instruction opcode
   (or maybe R3 for the debug l.nop instructions when running under a simulator). When writing,
   the CPU will normally use some GPR number specified in the instruction opcode, although a few of
   the jump instructions always write to the link register R9.

   After the execution phase of our example l.sll instruction, the CPU needs another clock edge to write
   the result to R1, as writes are always synchronous to the clock. The register write clock posedge
   is currently shared with the one that starts the fetch cycle for the next instruction,
   so that the previous instruction's register write and the next instruction's Wishbone fetch
   run in parallel.

   Note that a Wishbone fetch cycle can last several clock cycles, but the register write operation
   only uses the first posedge.

   --------------

   Copyright (C) 2012, R. Diez

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License version 3
   as published by the Free Software Foundation.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License version 3 for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

`include "simulator_features.v"
`include "or10_defines.v"


module or10_register_file (
                  input                            clk_i,

                  // Read results are delivered asynchronously but
                  // writes are issued synchronously to clk_i.
                  input [`OR10_REG_NUMBER]         register_number_1_i,

                  output [`OR10_OPERAND_WIDTH-1:0] data_1_o, // For reads.

                  input                            write_enable_1_i,
                  input [`OR10_OPERAND_WIDTH-1:0]  data_1_i, // For writes.

                  // Second port, read only. Read results are delivered asynchronously.
                  input [`OR10_REG_NUMBER]         register_number_2_i,
                  output [`OR10_OPERAND_WIDTH-1:0] data_2_o   // For reads.
                );

   // Mapping the register file to the FPGA's memory block is cumbersome.
   // Each FPGA has different memory block sizes and features,
   // and the OR10 CPU could also be implemented with more or less
   // GPRs, which could be 32 or 64 bits wide.
   //
   // When targetting Xilinx FPGAs, the AltOr32 OpenRISC implementation uses
   // Xilinx' RAM16X1D primitives (which implement async reads with distributed RAM),
   // and the OR1200 OpenRISC implementation uses RAMB16_S36_S36 primitives (which are also async
   // reads with distributed RAM) among other memory types.
   //
   // This implementation uses standard Verilog and is designed
   // to let Xilinx XST infer the right type of memory for Spartan-6 FPGAs. Inferring
   // is generally better than using vendor-specific primitives, this is an excerpt
   // from Xilinx' XST User Guide version 13.4:
   //
   //   XST extended Random Access Memory (RAM) inferencing:
   //   -  Makes it unnecessary to manually instantiate RAM primitives.
   //   -  Saves time.
   //   -  Keeps HDL source code portable and scalable.
   //
   // You may need to use alternative Verilog code or vendor-specific primitives
   // for other FPGAs.

   localparam GPR_COUNT = 32;

   reg [`OR10_OPERAND_WIDTH-1:0] cpureg_gprs[GPR_COUNT-1:0];  // General Purpose Registers.


   // Note that there is no read/write synchronisation in this implementation,
   // as the OR10 CPU does not need it at the moment.

   // Synchronous write.
   // This describes write access in a way that Xilinx XST recognises for Spartan-6 FPGAs:
   always @( posedge clk_i )
     begin
        if ( write_enable_1_i )
          begin
             // $display( "Register file: writing value 0x%08h to register R%0d", data_1_i, register_number_1_i );
             cpureg_gprs[ register_number_1_i ] <= data_1_i;
          end
     end

   // Asynchronous read.
   // This describes read access in a way that Xilinx XST recognises for Spartan-6 FPGAs:
   assign data_1_o = cpureg_gprs[ register_number_1_i ];
   assign data_2_o = cpureg_gprs[ register_number_2_i ];


   integer i;

   initial
     begin
        // Initialise all General Purpose Registers with a non-zero value, as this helps catch bugs
        // if the software forgets to initialise them. Note that the OpenRISC specification
        // does not mandate that the registers are initialised at all.
        for ( i = 0; i < GPR_COUNT; i = i + 1 )
          begin
             cpureg_gprs[i] = 32'h12345678;
          end
     end

endmodule
