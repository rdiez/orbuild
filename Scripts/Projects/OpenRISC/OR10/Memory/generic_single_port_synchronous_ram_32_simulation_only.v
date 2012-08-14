
/* Generic single-port, 32-bit synchronous RAM with a Wishbone interface.

   See file generic_single_port_synchronous_ram_32.v for more information
   about this module.

   This version is designed for Icarus Verilog, it uses just one 32-bit memory array
   that can be initialised at once from a file, which drastically reduces
   RAM consumption for the simulation (I was getting over 1,2 GB RAM usage
   for a mere 8 MB of simulated memory, as of August 2012).

   I did not want to study the memory inferencing quirks on Xilinx/Altera/whatever platforms,
   so I wrote this module with only Icarus Verilog in mind (although it works with other simulators too).
   Due to the Wishbone byte-enable signals (wb_sel_i), FPGA synthesisers will probably not infer
   any built-in RAM blocks.

   Note that, when initialising the memory contents, the .hex file must have 32-bits' worth of data
   per line (as opposed to 8-bit per line for the other module version).

   -------------------

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

module generic_single_port_synchronous_ram_32_simulation_only
  #( parameter ADR_WIDTH = 11,  // Each memory location is 32 bits (4 bytes) wide. A width of 11 is then 2^(11+2) = 8 KB of RAM.
     parameter MEMORY_FILENAME = "",
     parameter MEMORY_FILESIZE = 0,  // In 32-bit words.
     parameter GET_MEMORY_FILENAME_FROM_SIM_ARGS = 0
   )
  (
    input             wb_clk_i,
    input             wb_rst_i,

    input [31:0]      wb_dat_i,
    output reg [31:0] wb_dat_o,
    input [31:0]      wb_adr_i,
    input [3:0]       wb_sel_i,
    input             wb_we_i,
    input             wb_cyc_i,
    input             wb_stb_i,
    output reg        wb_ack_o,
    output reg        wb_err_o
  );

   // The last 2 bits of the address are not actually used.
   wire           prevent_unused_warning_with_verilator = &{ 1'b0,
                                                             wb_adr_i[1:0],
                                                             1'b0 };
   wire           is_beginning_of_wishbone_operation;
   wire           is_out_of_bounds;

   assign is_beginning_of_wishbone_operation = !wb_rst_i  &&
                                                wb_cyc_i  &&
                                                wb_stb_i  &&
                                               !wb_ack_o  && // If we answered in the last cycle, finish the transaction in this one
                                               !wb_err_o;    // by clearing wb_ack_o and wb_err_o.

   assign is_out_of_bounds = ( 0 != wb_adr_i[31:ADR_WIDTH+2] );

   reg [31:0] mem_contents [(1<<ADR_WIDTH)-1:0];

   always @(posedge wb_clk_i)
     begin
        wb_dat_o <= 32'bx;

        if ( is_beginning_of_wishbone_operation )
          begin
             if ( is_out_of_bounds )
               begin
                  wb_err_o <= 1;
                  wb_ack_o <= 0;
               end
             else
               begin
                  wb_err_o <= 0;
                  wb_ack_o <= 1;

                  if ( wb_we_i )
                    begin
                       if ( wb_sel_i[0] ) mem_contents[ wb_adr_i[ADR_WIDTH+1:2] ][ 7: 0] <= wb_dat_i[ 7: 0];
                       if ( wb_sel_i[1] ) mem_contents[ wb_adr_i[ADR_WIDTH+1:2] ][15: 8] <= wb_dat_i[15: 8];
                       if ( wb_sel_i[2] ) mem_contents[ wb_adr_i[ADR_WIDTH+1:2] ][23:16] <= wb_dat_i[23:16];
                       if ( wb_sel_i[3] ) mem_contents[ wb_adr_i[ADR_WIDTH+1:2] ][31:24] <= wb_dat_i[31:24];
                    end
                  else
                    begin
                       if ( wb_sel_i[0] ) wb_dat_o[ 7: 0] <= mem_contents[ wb_adr_i[ADR_WIDTH+1:2] ][ 7: 0];
                       if ( wb_sel_i[1] ) wb_dat_o[15: 8] <= mem_contents[ wb_adr_i[ADR_WIDTH+1:2] ][15: 8];
                       if ( wb_sel_i[2] ) wb_dat_o[23:16] <= mem_contents[ wb_adr_i[ADR_WIDTH+1:2] ][23:16];
                       if ( wb_sel_i[3] ) wb_dat_o[31:24] <= mem_contents[ wb_adr_i[ADR_WIDTH+1:2] ][31:24];
                    end
               end
          end
        else
          begin
             wb_ack_o <= 0;
             wb_err_o <= 0;
          end
     end


   // -------- Optionally initialise the memory contents --------
   // With Xilinx XST (as of version 13.4), you cannot initialise the RAM from the upper level module directly,
   // it does not seem possible to access any submodule internal signals. Therefore, memory initialisation
   // must be done in the lower level. However, that means that there are 4 copies of the file contents,
   // one per submodule, and that makes Icarus Verilog consume great amounts of RAM. That's the reason why
   // there are 2 copies of the memory initialisation code. When using this copy here, we save RAM under
   // Icarus Verilog. The other copy is in the 'generic_single_port_synchronous_ram_8_from_32' submodule.

   reg [255*8-1:0] arg_filename;
   integer         arg_filesize;

   localparam      MAX_FILE_SIZE = 1<<(ADR_WIDTH+2);

   initial
     begin
        if ( GET_MEMORY_FILENAME_FROM_SIM_ARGS || MEMORY_FILENAME != "" )
          begin
             if ( GET_MEMORY_FILENAME_FROM_SIM_ARGS )
               begin
                  // Get the .hex firmware filename from the simulation's command line.
                  if ( $value$plusargs( "file_name=%s", arg_filename ) == 0 || arg_filename == 0 )
                    begin
                       $display("ERROR: Please specify the name of the firmware file to load on start-up.");
                       $finish;
                    end

                  // We are passing the firmware size separately as a command-line argument in order
                  // to avoid this kind of Icarus Verilog warnings:
                  //   WARNING: $readmemh: Standard inconsistency, following 1364-2005.
                  //   WARNING: $readmemh(../../sw/uart/uart.hex): Not enough words in the file for the requested range [0:32767].
                  // Apparently, some of the $readmemh() warnigns are even required by the standard. The trouble is,
                  // Verilog's $fread() is not widely implemented in the simulators, so from Verilog alone
                  // it's not easy to read the firmware file header without getting such warnings.
                  if ( $value$plusargs("firmware_size=%d", arg_filesize) == 0 )
                    begin
                       $display("ERROR: Please specify the size of the firmware (in bytes) contained in the hex firmware file.");
                       $finish;
                    end

                  $readmemh( arg_filename, mem_contents, 0, arg_filesize - 1 );

                  if ( arg_filesize * 4 != mem_contents[0] )
                    begin
                       $display("ERROR: The firmware size in the file header does not match the firmware size given as command-line argument. Did you forget bin2hex's -size_word flag when generating the firmware file?");
                       $finish;
                    end
               end
             else
               begin
                  // Xilinx XST (as of version 13.4) does not support calling $readmemh() with a non-constant
                  // filename argument, so that's the reason this call is separated here.
                  $readmemh( MEMORY_FILENAME, mem_contents, 0, MEMORY_FILESIZE - 1 );
               end
          end
     end

endmodule
