
/* SoC for the OR10 CPU, designed to run the Test Suite.

   Copyright (C) 2011, Raul Fajardo, rfajardo@gmail.com
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

`include "or1200_defines.v"


module soc_top ( input wire         wb_clk_i,
                 input wire         wb_rst_i,

                 // ------ UART Wishbone signals ------
                 output wire [31:0] wb_uart_dat_o,
                 input wire [31:0]  wb_uart_dat_i,
                 output wire [23:0] wb_uart_adr_o,
                 output wire [3:0]  wb_uart_sel_o,
                 output wire        wb_uart_we_o,
                 output wire        wb_uart_cyc_o,
                 output wire        wb_uart_stb_o,
                 input wire         wb_uart_ack_i,
                 input wire         wb_uart_err_i,
                 input wire         uart_int_i
               );

   parameter MEMORY_FILENAME = "";
   parameter integer MEMORY_FILESIZE = 0;
   parameter GET_MEMORY_FILENAME_FROM_SIM_ARGS = 0;
   parameter MEMORY_ADR_WIDTH = 2;

   // CPU Wishbone bus.
   wire [31:0]  wb_cpu_adr_o;
   wire         wb_cpu_cyc_o;
   wire [31:0]  wb_cpu_dat_i;
   wire [31:0]  wb_cpu_dat_o;
   wire [3:0]   wb_cpu_sel_o;
   wire         wb_cpu_ack_i;
   wire         wb_cpu_err_i;
   wire         wb_cpu_rty_i = 1'b0;
   wire         wb_cpu_we_o;
   wire         wb_cpu_stb_o;

   // SRAM controller Wishbone bus
   wire [31:0]  wb_ss_dat_i;
   wire [31:0]  wb_ss_dat_o;
   wire [31:0]  wb_ss_adr_i;
   wire [3:0]   wb_ss_sel_i;
   wire         wb_ss_we_i;
   wire         wb_ss_cyc_i;
   wire         wb_ss_stb_i;
   wire         wb_ss_ack_o;
   wire         wb_ss_err_o;


   `define APP_INT_UART  2
   `define APP_INT_REST1  31:3
   `define APP_INT_REST2  1:0

   wire [31:0] pic_ints;
   assign pic_ints[`APP_INT_REST1] = 0;
   assign pic_ints[`APP_INT_REST2] = 0;
   assign pic_ints[ `APP_INT_UART ] = uart_int_i;


   or10_top or10_top_instance (

     .wb_clk_i  ( wb_clk_i ),
     .wb_rst_i  ( wb_rst_i ),
     .wb_cyc_o  ( wb_cpu_cyc_o ),
     .wb_adr_o  ( wb_cpu_adr_o ),
     .wb_dat_i  ( wb_cpu_dat_i ),
     .wb_dat_o  ( wb_cpu_dat_o ),
     .wb_sel_o  ( wb_cpu_sel_o ),
     .wb_ack_i  ( wb_cpu_ack_i ),
     .wb_err_i  ( wb_cpu_err_i ),
     .wb_rty_i  ( wb_cpu_rty_i ),
     .wb_we_o   ( wb_cpu_we_o  ),
     .wb_stb_o  ( wb_cpu_stb_o ),
     .pic_ints_i( pic_ints     )
   );


   `ifdef __ICARUS__
     generic_single_port_synchronous_ram_32_simulation_only
   `else
     generic_single_port_synchronous_ram_32
   `endif
     #(
      .ADR_WIDTH( MEMORY_ADR_WIDTH ),
      .MEMORY_FILENAME( MEMORY_FILENAME ),
      .MEMORY_FILESIZE( MEMORY_FILESIZE ),
      .GET_MEMORY_FILENAME_FROM_SIM_ARGS( GET_MEMORY_FILENAME_FROM_SIM_ARGS )
     )
   soc_memory (

    // WISHBONE common
    .wb_clk_i( wb_clk_i ),
    .wb_rst_i( wb_rst_i ),

    // WISHBONE slave
    .wb_dat_i( wb_ss_dat_i ),
    .wb_dat_o( wb_ss_dat_o ),
    .wb_adr_i( wb_ss_adr_i ),
    .wb_sel_i( wb_ss_sel_i ),
    .wb_we_i ( wb_ss_we_i  ),
    .wb_cyc_i( wb_ss_cyc_i ),
    .wb_stb_i( wb_ss_stb_i ),
    .wb_ack_o( wb_ss_ack_o ),
    .wb_err_o( wb_ss_err_o )
   );


   // Address map (most of it not used by the Test Suite).
  `define APP_ADDR_DEC_W      8
  `define APP_ADDR_SRAM       `APP_ADDR_DEC_W'h00
  `define APP_ADDR_FLASH      `APP_ADDR_DEC_W'h04
  `define APP_ADDR_DECP_W     4
  `define APP_ADDR_PERIP      `APP_ADDR_DECP_W'h9
  `define APP_ADDR_SPI        `APP_ADDR_DEC_W'h97
  `define APP_ADDR_ETH        `APP_ADDR_DEC_W'h92
  `define APP_ADDR_AUDIO      `APP_ADDR_DEC_W'h9d
  `define APP_ADDR_UART       `APP_ADDR_DEC_W'h90
  `define APP_ADDR_PS2        `APP_ADDR_DEC_W'h94
  `define APP_ADDR_JSP        `APP_ADDR_DEC_W'h9e
  `define APP_ADDR_RES2       `APP_ADDR_DEC_W'h9f

   wire [31:0] wb_uart_adr_o_32;  // The upper byte [31:24] is always `APP_ADDR_UART.
   assign wb_uart_adr_o = wb_uart_adr_o_32[23:0];


   // Given that the OR10 CPU has only one Wishbone interface,
   // we could use a simpler Wishbone Traffic Switch (Interconnect).
   minsoc_tc_top #(`APP_ADDR_DEC_W,
                   `APP_ADDR_SRAM,
                   `APP_ADDR_DEC_W,
                   `APP_ADDR_FLASH,
                   `APP_ADDR_DECP_W,
                   `APP_ADDR_PERIP,
                   `APP_ADDR_DEC_W,
                   `APP_ADDR_SPI,
                   `APP_ADDR_ETH,
                   `APP_ADDR_AUDIO,
                   `APP_ADDR_UART,
                   `APP_ADDR_PS2,
                   `APP_ADDR_JSP,
                   `APP_ADDR_RES2
                   ) tc_top (

    // WISHBONE common
    .wb_clk_i   ( wb_clk_i ),
    .wb_rst_i   ( wb_rst_i ),

    // WISHBONE Initiator 0 (unused)
    .i0_wb_cyc_i    ( 1'b0 ),
    .i0_wb_stb_i    ( 1'b0 ),
    .i0_wb_adr_i    ( 32'h0000_0000 ),
    .i0_wb_sel_i    ( 4'b0000 ),
    .i0_wb_we_i ( 1'b0 ),
    .i0_wb_dat_i    ( 32'h0000_0000 ),
    .i0_wb_dat_o    ( ),
    .i0_wb_ack_o    ( ),
    .i0_wb_err_o    ( ),

    // WISHBONE Initiator 1 (unused)
    .i1_wb_cyc_i    ( 1'b0 ),
    .i1_wb_stb_i    ( 1'b0 ),
    .i1_wb_adr_i    ( 32'h0000_0000 ),
    .i1_wb_sel_i    ( 4'b0000 ),
    .i1_wb_we_i ( 1'b0 ),
    .i1_wb_dat_i    ( 32'h0000_0000 ),
    .i1_wb_dat_o    ( ),
    .i1_wb_ack_o    ( ),
    .i1_wb_err_o    ( ),

    // WISHBONE Initiator 2 (unused)
    .i2_wb_cyc_i    ( 1'b0 ),
    .i2_wb_stb_i    ( 1'b0 ),
    .i2_wb_adr_i    ( 32'h0000_0000 ),
    .i2_wb_sel_i    ( 4'b0000 ),
    .i2_wb_we_i ( 1'b0 ),
    .i2_wb_dat_i    ( 32'h0000_0000 ),
    .i2_wb_dat_o    ( ),
    .i2_wb_ack_o    ( ),
    .i2_wb_err_o    ( ),

    // WISHBONE Initiator 3 (unused)
    .i3_wb_cyc_i    ( 1'b0 ),
    .i3_wb_stb_i    ( 1'b0 ),
    .i3_wb_adr_i    ( 32'h0000_0000 ),
    .i3_wb_sel_i    ( 4'b0000 ),
    .i3_wb_we_i ( 1'b0 ),
    .i3_wb_dat_i    ( 32'h0000_0000 ),
    .i3_wb_dat_o    ( ),
    .i3_wb_ack_o    ( ),
    .i3_wb_err_o    ( ),

    // WISHBONE Initiator 4
    .i4_wb_cyc_i    ( 1'b0 ),
    .i4_wb_stb_i    ( 1'b0 ),
    .i4_wb_adr_i    ( 32'h0000_0000 ),
    .i4_wb_sel_i    ( 4'b0000 ),
    .i4_wb_we_i ( 1'b0 ),
    .i4_wb_dat_i    ( 32'h0000_0000 ),
    .i4_wb_dat_o    ( ),
    .i4_wb_ack_o    ( ),
    .i4_wb_err_o    ( ),

    // WISHBONE Initiator 5
    .i5_wb_cyc_i    ( wb_cpu_cyc_o ),
    .i5_wb_stb_i    ( wb_cpu_stb_o ),
    .i5_wb_adr_i    ( wb_cpu_adr_o ),
    .i5_wb_sel_i    ( wb_cpu_sel_o ),
    .i5_wb_we_i     ( wb_cpu_we_o  ),
    .i5_wb_dat_i    ( wb_cpu_dat_o ),
    .i5_wb_dat_o    ( wb_cpu_dat_i ),
    .i5_wb_ack_o    ( wb_cpu_ack_i ),
    .i5_wb_err_o    ( wb_cpu_err_i ),

    // WISHBONE Initiator 6 (unused)
    .i6_wb_cyc_i    ( 1'b0 ),
    .i6_wb_stb_i    ( 1'b0 ),
    .i6_wb_adr_i    ( 32'h0000_0000 ),
    .i6_wb_sel_i    ( 4'b0000 ),
    .i6_wb_we_i ( 1'b0 ),
    .i6_wb_dat_i    ( 32'h0000_0000 ),
    .i6_wb_dat_o    ( ),
    .i6_wb_ack_o    ( ),
    .i6_wb_err_o    ( ),

    // WISHBONE Initiator 7 (unused)
    .i7_wb_cyc_i    ( 1'b0 ),
    .i7_wb_stb_i    ( 1'b0 ),
    .i7_wb_adr_i    ( 32'h0000_0000 ),
    .i7_wb_sel_i    ( 4'b0000 ),
    .i7_wb_we_i ( 1'b0 ),
    .i7_wb_dat_i    ( 32'h0000_0000 ),
    .i7_wb_dat_o    ( ),
    .i7_wb_ack_o    ( ),
    .i7_wb_err_o    ( ),

    // WISHBONE Target 0 - SRAM controller
    // NOTE: This target has its own bus and can be accessed in parallel
    //       to the other targets.
    .t0_wb_cyc_o    ( wb_ss_cyc_i ),
    .t0_wb_stb_o    ( wb_ss_stb_i ),
    .t0_wb_adr_o    ( wb_ss_adr_i ),
    .t0_wb_sel_o    ( wb_ss_sel_i ),
    .t0_wb_we_o     ( wb_ss_we_i  ),
    .t0_wb_dat_o    ( wb_ss_dat_i ),
    .t0_wb_dat_i    ( wb_ss_dat_o ),
    .t0_wb_ack_i    ( wb_ss_ack_o ),
    .t0_wb_err_i    ( wb_ss_err_o ),

    // WISHBONE Target 1 - Flash controller
    .t1_wb_cyc_o    ( ),
    .t1_wb_stb_o    ( ),
    .t1_wb_adr_o    ( ),
    .t1_wb_sel_o    ( ),
    .t1_wb_we_o ( ),
    .t1_wb_dat_o    ( ),
    .t1_wb_dat_i    ( 32'h0000_0000 ),
    .t1_wb_ack_i    ( 1'b0 ),
    .t1_wb_err_i    ( 1'b1 ),

    // WISHBONE Target 2 (unused)
    .t2_wb_cyc_o    ( ),
    .t2_wb_stb_o    ( ),
    .t2_wb_adr_o    ( ),
    .t2_wb_sel_o    ( ),
    .t2_wb_we_o ( ),
    .t2_wb_dat_o    ( ),
    .t2_wb_dat_i    ( 32'h0000_0000 ),
    .t2_wb_ack_i    ( 1'b0 ),
    .t2_wb_err_i    ( 1'b1 ),

    // WISHBONE Target 3 (unused)
    .t3_wb_cyc_o    ( ),
    .t3_wb_stb_o    ( ),
    .t3_wb_adr_o    ( ),
    .t3_wb_sel_o    ( ),
    .t3_wb_we_o ( ),
    .t3_wb_dat_o    ( ),
    .t3_wb_dat_i    ( 32'h0000_0000 ),
    .t3_wb_ack_i    ( 1'b0 ),
    .t3_wb_err_i    ( 1'b1 ),

    // WISHBONE Target 4 (unused)
    .t4_wb_cyc_o    ( ),
    .t4_wb_stb_o    ( ),
    .t4_wb_adr_o    ( ),
    .t4_wb_sel_o    ( ),
    .t4_wb_we_o ( ),
    .t4_wb_dat_o    ( ),
    .t4_wb_dat_i    ( 32'h0000_0000 ),
    .t4_wb_ack_i    ( 1'b0 ),
    .t4_wb_err_i    ( 1'b1 ),

    // WISHBONE Target 5 (UART)
    .t5_wb_cyc_o    ( wb_uart_cyc_o ),
    .t5_wb_stb_o    ( wb_uart_stb_o ),
    .t5_wb_adr_o    ( wb_uart_adr_o_32 ),
    .t5_wb_sel_o    ( wb_uart_sel_o ),
    .t5_wb_we_o     ( wb_uart_we_o  ),
    .t5_wb_dat_o    ( wb_uart_dat_o ),
    .t5_wb_dat_i    ( wb_uart_dat_i ),
    .t5_wb_ack_i    ( wb_uart_ack_i ),
    .t5_wb_err_i    ( wb_uart_err_i ),

    // WISHBONE Target 6 (unused)
    .t6_wb_cyc_o    ( ),
    .t6_wb_stb_o    ( ),
    .t6_wb_adr_o    ( ),
    .t6_wb_sel_o    ( ),
    .t6_wb_we_o ( ),
    .t6_wb_dat_o    ( ),
    .t6_wb_dat_i    ( 32'h0000_0000 ),
    .t6_wb_ack_i    ( 1'b0 ),
    .t6_wb_err_i    ( 1'b1 ),

    // WISHBONE Target 7 (unused)
    .t7_wb_cyc_o    ( ),
    .t7_wb_stb_o    ( ),
    .t7_wb_adr_o    ( ),
    .t7_wb_sel_o    ( ),
    .t7_wb_we_o ( ),
    .t7_wb_dat_o    ( ),
    .t7_wb_dat_i    ( 32'h0000_0000 ),
    .t7_wb_ack_i    ( 1'b0 ),
    .t7_wb_err_i    ( 1'b1 ),

    // WISHBONE Target 8 (unused)
    .t8_wb_cyc_o    ( ),
    .t8_wb_stb_o    ( ),
    .t8_wb_adr_o    ( ),
    .t8_wb_sel_o    ( ),
    .t8_wb_we_o ( ),
    .t8_wb_dat_o    ( ),
    .t8_wb_dat_i    ( 32'h0000_0000 ),
    .t8_wb_ack_i    ( 1'b0 ),
    .t8_wb_err_i    ( 1'b1 )
   );

endmodule
