
/* Generic single-port, 8-bit synchronous RAM, designed as an 8-bit memory component for a 32-bit Wishbone RAM.

   The memory contents are (optionally) initialised from a file, see the module parameters for more information.
   The file must be generated with MinSoC's bin2hex tool and its size must be aligned to a 32-bit (4 byte) boundary.
   Use bin2hex' argument -size_word so that the first 32-bit word contains the file size
   (this check could be disabled in the source code below).

   Xilinx' XST infers a Block RAM out of this memory, at least with version 13.4 for an Spartan-6,
   which helps conserve FPGA LUT resources. The exact type inferred is:
      Found 4096x8-bit single-port RAM <Mram_mem_contents> for signal <mem_contents>.

   Xilinx' XST supports inferring Block RAM byte-write enable signals, therefore it could be possible
   to write a single 32-bit Wishbone memory component, instead of joining 4 8-bit components together.


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

module generic_single_port_synchronous_ram_8_from_32
  #( parameter ADDR_WIDTH = 11,  // Each memory location is 8 bits wide. A width of 11 is then 2^11 = 2 KB of RAM.
     parameter MEMORY_FILENAME = "",
     parameter MEMORY_FILESIZE = 0,
     parameter GET_MEMORY_FILENAME_FROM_SIM_ARGS = 0,  // MEMORY_FILENAME is a parameter and can only be a constant string, so we need this alternative parameter for simulation.
     parameter MEMORY_FILE_BYTE_OFFSET = 0   // On a 32-bit memory system, big endian, the 8 bits [31:24] have an offset of 0.
   )
  (
   input                  clk_i,
   input                  we_i, // Write enable.
   input [ADDR_WIDTH-1:0] addr_i,
   input [7:0]            data_i,
   output reg [7:0]       data_o
  );

   reg [7:0]              mem_contents [(1<<ADDR_WIDTH)-1:0];

   always @(posedge clk_i)
     begin
        if ( we_i )
          begin
             mem_contents[ addr_i ] <= data_i;

             // There is no need for read/write synchronisation: we are either reading
             // or writing, but not both at the same clock posedge.
             data_o <= {8{1'bx}};
          end
        else
          begin
             data_o <= mem_contents[ addr_i ];
          end
     end


   // -------- Optionally initialise the memory contents --------
   // This code is duplicated in the parent module, see the comments there for more information.
  `ifndef CAN_ACCESS_INTERNAL_SIGNALS

     reg [255*8-1:0] arg_filename;
     integer         arg_filesize;
     integer         firmware_size_in_header;

     localparam    MAX_FILE_SIZE = 1<<(ADDR_WIDTH+2);
     reg [7:0]     file_contents[ MAX_FILE_SIZE-1 : 0 ];
     integer       i;

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

                    $readmemh( arg_filename, file_contents, 0, arg_filesize - 1 );

                    firmware_size_in_header = { file_contents[0] , file_contents[1] , file_contents[2] , file_contents[3] };

                    if ( arg_filesize != firmware_size_in_header )
                      begin
                         $display("ERROR: The firmware size in the file header does not match the firmware size given as command-line argument. Did you forget bin2hex's -size_word flag when generating the firmware file?");
                         $finish;
                      end
                 end
               else
                 begin
                    // Xilinx XST (as of version 13.4) does not support calling $readmemh() with a non-constant
                    // filename argument, so that's the reason this call is separated here.
                    $readmemh( MEMORY_FILENAME, file_contents, 0, MEMORY_FILESIZE - 1 );
                 end

               // Take 1 byte out of each 4 bytes in the file.
               for ( i = 0; i < MAX_FILE_SIZE; i = i + 4 )
                 begin
                    mem_contents[i/4] = file_contents[ i + MEMORY_FILE_BYTE_OFFSET ];
                 end
            end
       end
  `endif  // `ifndef CAN_ACCESS_INTERNAL_SIGNALS

endmodule
