
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
        .wb_clk_i   ( clock ),
        .wb_rst_i   ( reset ),

        .wb_adr_i   ( wb_uart_adr ),  // The highest address byte [31,24] is fixed to APP_ADDR_UART.
        .wb_dat_i   ( wb_uart_dat_to_uart ),
        .wb_dat_o   ( wb_uart_dat_from_uart ),
        .wb_we_i    ( wb_uart_we  ),
        .wb_stb_i   ( wb_uart_stb ),
        .wb_cyc_i   ( wb_uart_cyc ),
        .wb_ack_o   ( wb_uart_ack ),
        .wb_sel_i   ( wb_uart_sel ),

        .int_o      ( uart_int )
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


   // ----------- Instanciate the Ethernet interface -----------

   wire [31:0] wb_eth_dat_to_eth;
   wire [31:0] wb_eth_dat_from_eth;
   wire [31:0] wb_eth_adr;
   wire [3:0]  wb_eth_sel;
   wire        wb_eth_we;
   wire        wb_eth_cyc;
   wire        wb_eth_stb;
   wire        wb_eth_ack;
   wire        wb_eth_err;

   // The Ethernet module has a Wishbone master interface for DMA transfers.
   wire [31:0] wb_ethm_adr;
   wire [3:0]  wb_ethm_sel;
   wire        wb_ethm_we;
   wire [31:0] wb_ethm_dat_from_eth;
   wire [31:0] wb_ethm_dat_to_eth;
   wire        wb_ethm_cyc;
   wire        wb_ethm_stb;
   wire        wb_ethm_ack;
   wire        wb_ethm_err;

   wire        eth_int;

   `ifdef ENABLE_DPI_MODULES

     ethernet_dpi
     ethernet_dpi_instance1
       (
        .wb_clk_i   ( clock ),
        .wb_rst_i   ( reset ),

        .wb_adr_i   ( { 8'b0, wb_eth_adr[23:0] } ),  // The highest address byte [31,24] is always to APP_ADDR_ETH.
        .wb_dat_i   ( wb_eth_dat_to_eth ),
        .wb_dat_o   ( wb_eth_dat_from_eth ),
        .wb_we_i    ( wb_eth_we  ),
        .wb_stb_i   ( wb_eth_stb ),
        .wb_cyc_i   ( wb_eth_cyc ),
        .wb_ack_o   ( wb_eth_ack ),
        .wb_err_o   ( wb_eth_err ),
        .wb_sel_i   ( wb_eth_sel ),

        .m_wb_adr_o ( wb_ethm_adr ),
        .m_wb_dat_i ( wb_ethm_dat_to_eth ),
        .m_wb_dat_o ( wb_ethm_dat_from_eth ),
        .m_wb_we_o  ( wb_ethm_we  ),
        .m_wb_stb_o ( wb_ethm_stb ),
        .m_wb_cyc_o ( wb_ethm_cyc ),
        .m_wb_ack_i ( wb_ethm_ack ),
        .m_wb_err_i ( wb_ethm_err ),
        .m_wb_sel_o ( wb_ethm_sel ),

        .int_o      ( eth_int )
        );

     wire prevent_unused_warning_with_verilator_eth_addr = &{ 1'b0,
                                                              wb_eth_adr[31:24],
                                                              1'b0 };

   `else  // `ifdef ENABLE_DPI_MODULES

     assign wb_eth_dat_from_eth = 32'h0000_0000;
     assign wb_eth_ack = 0;
     assign wb_eth_err = 1;

     assign wb_ethm_adr = 0;
     assign wb_ethm_dat_from_eth = 0;
     assign wb_ethm_we = 0;
     assign wb_ethm_stb = 0;
     assign wb_ethm_cyc = 0;
     assign wb_ethm_sel = 0;

     assign eth_int = 0;

     wire   prevent_unused_warning_with_verilator_eth = &{ 1'b0,
                                                         wb_eth_dat_to_eth,
                                                         wb_eth_adr,
                                                         wb_eth_sel,
                                                         wb_eth_we,
                                                         wb_eth_cyc,
                                                         wb_eth_stb,

                                                         wb_ethm_dat_to_eth,
                                                         wb_ethm_ack,
                                                         wb_ethm_err,

                                                         1'b0 };

   `endif  // `ifdef ENABLE_DPI_MODULES


   // ----------- Instanciate the JTAG Debug Interface -----------

   wire jtag_tms;
   wire jtag_tck;
   wire jtag_trst;
   wire jtag_tdi;
   wire jtag_tdo;

   `ifdef ENABLE_DPI_MODULES

     jtag_dpi
         #( .PRINT_RECEIVED_JTAG_DATA( 0 ) )
       jtag_dpi_instance
         (
          .system_clk ( clock  ),
          .jtag_tms_o ( jtag_tms  ),
          .jtag_tck_o ( jtag_tck  ),
          .jtag_trst_o( jtag_trst ),
          .jtag_tdi_o ( jtag_tdi  ),
          .jtag_tdo_i ( jtag_tdo  )
         );

   `else  // `ifdef ENABLE_DPI_MODULES

     assign jtag_tms  = 0;
     assign jtag_tck  = 0;
     assign jtag_trst = 1;
     assign jtag_tdi  = 0;

     wire prevent_unused_warning_with_verilator_jtag = &{ 1'b0,
                                                          jtag_tdo,
                                                          1'b0 };

   `endif  // `ifdef ENABLE_DPI_MODULES

   wire is_tap_state_test_logic_reset;
   wire is_tap_state_shift_dr;
   wire is_tap_state_update_dr;
   wire is_tap_current_instruction_debug;
   wire debug_tdo;

   tap_top tap_top_instance
       (
        .jtag_tms_i  ( jtag_tms  ),
        .jtag_tck_i  ( jtag_tck  ),
        .jtag_trstn_i( jtag_trst ),
        .jtag_tdi_i  ( jtag_tdi  ),
        .jtag_tdo_o  ( jtag_tdo  ),

        .is_tap_state_test_logic_reset_o( is_tap_state_test_logic_reset ),
        .is_tap_state_shift_dr_o        ( is_tap_state_shift_dr   ),
        .is_tap_state_update_dr_o       ( is_tap_state_update_dr  ),
        .is_tap_state_capture_dr_o      (),

        .is_tap_current_instruction_debug_o( is_tap_current_instruction_debug ),

        .debug_tdo_i( debug_tdo )
       );


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
       .uart_int_i( uart_int ),

       .wb_eth_dat_o( wb_eth_dat_to_eth ),
       .wb_eth_dat_i( wb_eth_dat_from_eth ),
       .wb_eth_adr_o( wb_eth_adr ),
       .wb_eth_sel_o( wb_eth_sel ),
       .wb_eth_we_o ( wb_eth_we  ),
       .wb_eth_cyc_o( wb_eth_cyc ),
       .wb_eth_stb_o( wb_eth_stb ),
       .wb_eth_ack_i( wb_eth_ack ),
       .wb_eth_err_i( wb_eth_err ),

       .wb_ethm_adr_i( wb_ethm_adr ),
       .wb_ethm_dat_o( wb_ethm_dat_to_eth ),
       .wb_ethm_dat_i( wb_ethm_dat_from_eth ),
       .wb_ethm_sel_i( wb_ethm_sel ),
       .wb_ethm_we_i ( wb_ethm_we ),
       .wb_ethm_stb_i( wb_ethm_stb ),
       .wb_ethm_cyc_i( wb_ethm_cyc ),
       .wb_ethm_ack_o( wb_ethm_ack ),
       .wb_ethm_err_o( wb_ethm_err ),

       .eth_int_i( eth_int ),

       .jtag_tck_i(jtag_tck),
       .jtag_tdi_i(jtag_tdi),
       .is_tap_state_test_logic_reset_i( is_tap_state_test_logic_reset ),
       .is_tap_state_shift_dr_i( is_tap_state_shift_dr ),
       .is_tap_state_update_dr_i( is_tap_state_update_dr ),
       .is_tap_current_instruction_debug_i( is_tap_current_instruction_debug ),
       .debug_tdo_o( debug_tdo )
     );


   // ----------- Limit the simulation time -----------

   simulation_timeout simulation_timeout_instance( clock );

endmodule
