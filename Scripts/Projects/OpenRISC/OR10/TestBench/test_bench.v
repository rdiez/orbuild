
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


   // ----------- Print the firmware filename (it is loaded later) -----------

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


   // ----------- Instanciate the UART -----------

   wire [31:0] wb_uart_dat_to_uart;
   wire [31:0] wb_uart_dat_from_uart;
   wire [23:0] wb_uart_adr;
   wire [3:0]  wb_uart_sel;
   wire        wb_uart_we;
   wire        wb_uart_cyc;
   wire        wb_uart_stb;
   wire        wb_uart_ack;
   wire        wb_uart_err;

   wire        uart_int;

   `ifdef ENABLE_DPI_MODULES

     localparam UART_TCP_PORT = 5678;

     uart_dpi
       #( .UART_DPI_ADDR_WIDTH( 24 ),
          .tcp_port(UART_TCP_PORT),
          .port_name("UART DPI number 1"),
          .welcome_message( "--- Welcome to the first UART DPI port ---\n\r" )
          )
     uart_dpi_instance1
       (
	    .wb_clk_i	( clock ),
	    .wb_rst_i	( reset ),

	    .wb_adr_i	( wb_uart_adr ),  // The highest address byte [31,24] is fixed to APP_ADDR_UART.
	    .wb_dat_i	( wb_uart_dat_to_uart ),
	    .wb_dat_o	( wb_uart_dat_from_uart ),
	    .wb_we_i	( wb_uart_we  ),
	    .wb_stb_i	( wb_uart_stb ),
	    .wb_cyc_i	( wb_uart_cyc ),
	    .wb_ack_o	( wb_uart_ack ),
	    .wb_sel_i	( wb_uart_sel ),

	    .int_o		( uart_int )
        );

     assign wb_uart_err = 1'b0;  // The UART DPI module does not support signal wb_err yet.

   `else  // `ifdef ENABLE_DPI_MODULES

     assign wb_uart_dat_from_uart = 32'h0000_0000;
     assign wb_uart_ack = 0;
     assign wb_uart_err = 1;
     assign uart_int = 0;

     wire prevent_unused_warning_with_verilator_uart = &{ 1'b0,
                                                          wb_uart_dat_to_uart,
                                                          wb_uart_adr,
                                                          wb_uart_sel,
                                                          wb_uart_we,
                                                          wb_uart_cyc,
                                                          wb_uart_stb,
                                                          1'b0 };


   `endif  // `ifdef ENABLE_DPI_MODULES


   // ----------- Instanciate the SoC -----------

   soc_top
     # ( .MEMORY_ADR_WIDTH( MEMORY_ADR_WIDTH ),
         .GET_MEMORY_FILENAME_FROM_SIM_ARGS(1)  )
   soc_top_instance
     ( .wb_clk_i(clock),
       .wb_rst_i(reset),

       .wb_uart_dat_o( wb_uart_dat_to_uart ),
       .wb_uart_dat_i( wb_uart_dat_from_uart   ),
       .wb_uart_adr_o( wb_uart_adr ),
       .wb_uart_sel_o( wb_uart_sel ),
       .wb_uart_we_o ( wb_uart_we  ),
       .wb_uart_cyc_o( wb_uart_cyc ),
       .wb_uart_stb_o( wb_uart_stb ),
       .wb_uart_ack_i( wb_uart_ack ),
       .wb_uart_err_i( wb_uart_err ),
       .uart_int_i( uart_int )
     );


   // ----------- Limit the simulation time -----------

   simulation_timeout simulation_timeout_instance( clock );

endmodule
