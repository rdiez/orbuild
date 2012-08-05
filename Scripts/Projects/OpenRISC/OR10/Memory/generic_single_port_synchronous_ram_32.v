
/* Generic single-port, 32-bit synchronous RAM with a Wishbone interface.

   We cannot use any standard 32-bit memory, as the Wishbone interface
   requires the ability to write to single bytes or 16-bit words
   at any 32-bit memory position.

   Some FPGA memories, like Xilinx Spartan-6 Block RAMs, have a write-enable signal
   per byte which could fit the bill.

   This generic Verilog implementation breaks the 32-bit memory up into 4 separate
   8-bit memories and combines their write-enable signals with the Wishbone
   wb_sel_i signal in order to achieve that effect.

   The dedicated memory blocks in FPGAs tend to have a fixed size, so having
   4 of them could mean more memory than necessary is wasted at the end of each block.

   When initialising the memory contents, note that each 8-bit memory block
   reads the whole memory file and then extracts just the bytes it is interested in
   (that is, 1 byte out of each 4-byte sequence, see the MEMORY_FILE_BYTE_OFFSET parameter below).
   I tried to load the file only once in this module and then access the 8-bit arrays
   from here, but I could not get it to work with Xilinx XST (as of version 13.4).

   Note that, when reading, the wb_sel_i signal is ignored and the full 32-bits' worth of data
   is always returned. The Wishbone master will just pick up the ones it is interested about.


   Wishbone Datasheet

     General description:         32-bit slave, Wishbone B3
     Supported cycles:            SLAVE, READ/WRITE
     Data port, size:             32-bit
     Data port, granularity:      8-bit
     Data port, max operand size: 32-bit
     Data transfer ordering:      probably big endian (haven't looked into it yet)
     Data transfer sequencing:    Undefined

     wb_err_o is asserted for out-of-bounds memory addresses

     The Wishbone reset signal only affects the Wishbone interface and does not clear the memory contents.
     There is no need to assert reset at the beginning.


   This module is loosely based on Raul Fajardo's minsoc_memory_model module from the MinSoC project.

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


module generic_single_port_synchronous_ram_32
  #( parameter ADR_WIDTH = 11,  // Each memory location is 32 bits (4 bytes) wide. A width of 11 is then 2^(11+2) = 8 KB of RAM.
     parameter MEMORY_FILENAME = "",
     parameter MEMORY_FILESIZE = 0,
     parameter GET_MEMORY_FILENAME_FROM_SIM_ARGS = 0
   )
  (
    input wb_clk_i,
    input wb_rst_i,

    input  [31:0] wb_dat_i,
    output [31:0] wb_dat_o,
    input  [31:0] wb_adr_i,
    input  [3:0]  wb_sel_i,
    input         wb_we_i,
    input         wb_cyc_i,
    input         wb_stb_i,
    output reg    wb_ack_o,
    output reg    wb_err_o
  );

   // The last 2 bits of the address are not actually used.
   wire           prevent_unused_warning_with_verilator = &{ 1'b0,
                                                             wb_adr_i[1:0],
                                                             1'b0 };
   wire           is_beginning_of_wishbone_operation;
   wire           is_out_of_bounds;
   wire           write_enable_8_bit_blocks;

   assign is_beginning_of_wishbone_operation = !wb_rst_i  &&
                                                wb_cyc_i  &&
                                                wb_stb_i  &&
                                               !wb_ack_o  && // If we answered in the last cycle, finish the transaction in this one
                                               !wb_err_o;    // by clearing wb_ack_o and wb_err_o.

   assign is_out_of_bounds = ( 0 != wb_adr_i[31:ADR_WIDTH+2] );

   assign write_enable_8_bit_blocks = is_beginning_of_wishbone_operation &  // Only write at the 1st clock edge. At the 2nd clock edge
                                                                            // we assert wb_ack_o and there is no need to write again.
                                                                            // However, the master should keep the same address and data,
                                                                            // so writing again should actually do no harm.
                                      !is_out_of_bounds &  // If some high-order bits are set, do not use the lower ones to write
                                                           // to some wrong memory location.
                                      wb_we_i;

   // Note that, during Wishbone writes and when the memory address is out of range,
   // the 8-bit memories will continue to read from some location and present
   // the data in wb_dat_o, but that does not matter.

   always @( posedge wb_clk_i )
     begin
        if ( is_beginning_of_wishbone_operation )
          begin
             wb_err_o <=  is_out_of_bounds;
             wb_ack_o <= !is_out_of_bounds;
          end
        else
          begin
             wb_ack_o <= 0;
             wb_err_o <= 0;
          end
     end


    generic_single_port_synchronous_ram_8_from_32 #
    (
        .ADDR_WIDTH(ADR_WIDTH),
        .MEMORY_FILENAME( MEMORY_FILENAME ),
        .MEMORY_FILESIZE( MEMORY_FILESIZE ),
        .GET_MEMORY_FILENAME_FROM_SIM_ARGS( GET_MEMORY_FILENAME_FROM_SIM_ARGS ),
        .MEMORY_FILE_BYTE_OFFSET(3)
    )
    block_ram_0 (
        .clk_i(wb_clk_i),
        .addr_i(wb_adr_i[ADR_WIDTH+1:2]),
        .data_i(wb_dat_i[7:0]),
        .data_o(wb_dat_o[7:0]),
        .we_i( write_enable_8_bit_blocks & wb_sel_i[0] ) );

    generic_single_port_synchronous_ram_8_from_32 #
    (
        .ADDR_WIDTH(ADR_WIDTH),
        .MEMORY_FILENAME( MEMORY_FILENAME ),
        .MEMORY_FILESIZE( MEMORY_FILESIZE ),
        .GET_MEMORY_FILENAME_FROM_SIM_ARGS( GET_MEMORY_FILENAME_FROM_SIM_ARGS ),
        .MEMORY_FILE_BYTE_OFFSET(2)
    )
    block_ram_1 (
        .clk_i(wb_clk_i),
        .addr_i(wb_adr_i[ADR_WIDTH+1:2]),
        .data_i(wb_dat_i[15:8]),
        .data_o(wb_dat_o[15:8]),
        .we_i( write_enable_8_bit_blocks & wb_sel_i[1] ) );

    generic_single_port_synchronous_ram_8_from_32 #
    (
        .ADDR_WIDTH(ADR_WIDTH),
        .MEMORY_FILENAME( MEMORY_FILENAME ),
        .MEMORY_FILESIZE( MEMORY_FILESIZE ),
        .GET_MEMORY_FILENAME_FROM_SIM_ARGS( GET_MEMORY_FILENAME_FROM_SIM_ARGS ),
        .MEMORY_FILE_BYTE_OFFSET(1)
    )
    block_ram_2 (
        .clk_i(wb_clk_i),
        .addr_i(wb_adr_i[ADR_WIDTH+1:2]),
        .data_i(wb_dat_i[23:16]),
        .data_o(wb_dat_o[23:16]),
        .we_i( write_enable_8_bit_blocks & wb_sel_i[2] ) );

    generic_single_port_synchronous_ram_8_from_32 #
    (
        .ADDR_WIDTH(ADR_WIDTH),
        .MEMORY_FILENAME( MEMORY_FILENAME ),
        .MEMORY_FILESIZE( MEMORY_FILESIZE ),
        .GET_MEMORY_FILENAME_FROM_SIM_ARGS( GET_MEMORY_FILENAME_FROM_SIM_ARGS ),
        .MEMORY_FILE_BYTE_OFFSET(0)
    )
    block_ram_3 (
        .clk_i(wb_clk_i),
        .addr_i(wb_adr_i[ADR_WIDTH+1:2]),
        .data_i(wb_dat_i[31:24]),
        .data_o(wb_dat_o[31:24]),
        .we_i( write_enable_8_bit_blocks & wb_sel_i[3] ) );

endmodule
