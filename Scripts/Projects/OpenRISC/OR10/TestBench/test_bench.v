
/* Testbench for the OR10-based SoC

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


module test_bench ( input wire clock,
                    input wire reset );

   // Keep the memory size low, as Icarus Verilog needs lots of RAM to simulate 8-bit memory arrays.
   // 2^21 = 2 MBytes x 4 bytes (32 bits width) = 8 MBytes, which is enough for the Test Suite.
   // The test cases written in assembly need less than 1 MByte, but the Newlib-based ones
   // require 8 MB, as they allocate the stack at the upper end of the heap. When compiling software,
   // the target's memory size is either specified in the linker script file, or, when using newlib,
   // in the board support package, look for "_board_mem_size" in libgloss.
   parameter MEMORY_ADR_WIDTH = 21;

   reg [255*8-1:0] file_name;

   initial
     begin
        // The actual loading of the firmware file happens later, at this point we are only
        // displaying the filename.
        if ( $value$plusargs("file_name=%s", file_name) != 0 && file_name != 0 )
          begin
             // Note that Verilator can only display strings of up to 1024 bits / 8 = 128 characters.
             $display( "The RAM contents will be initialised from file: %0s", file_name[1023:0] );
          end
     end


   // ----------- Instanciate the SoC -----------

   soc_top
     # ( .MEMORY_ADR_WIDTH( MEMORY_ADR_WIDTH ),
         .GET_MEMORY_FILENAME_FROM_SIM_ARGS(1)  )
   soc_top_instance
     ( .wb_clk_i(clock),
       .wb_rst_i(reset) );

   simulation_timeout simulation_timeout_instance( clock );

endmodule
