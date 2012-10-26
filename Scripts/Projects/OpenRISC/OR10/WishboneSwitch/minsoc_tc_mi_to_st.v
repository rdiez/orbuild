//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2002 OpenCores                                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`include "simulator_features.v"
`include "minsoc_tc_defines.v"

//
// Multiple initiator to single target
//
module minsoc_tc_mi_to_st (
	wb_clk_i,
	wb_rst_i,

	i0_wb_cyc_i,  // If somebody was already using the bus, it will continue to do so. Otherwise, Initiator 0 has the highest priority.
	i0_wb_stb_i,
	i0_wb_adr_i,
	i0_wb_sel_i,
	i0_wb_we_i,
	i0_wb_dat_i,
	i0_wb_dat_o,
	i0_wb_ack_o,
	i0_wb_err_o,

	i1_wb_cyc_i,
	i1_wb_stb_i,
	i1_wb_adr_i,
	i1_wb_sel_i,
	i1_wb_we_i,
	i1_wb_dat_i,
	i1_wb_dat_o,
	i1_wb_ack_o,
	i1_wb_err_o,

	i2_wb_cyc_i,
	i2_wb_stb_i,
	i2_wb_adr_i,
	i2_wb_sel_i,
	i2_wb_we_i,
	i2_wb_dat_i,
	i2_wb_dat_o,
	i2_wb_ack_o,
	i2_wb_err_o,

	i3_wb_cyc_i,
	i3_wb_stb_i,
	i3_wb_adr_i,
	i3_wb_sel_i,
	i3_wb_we_i,
	i3_wb_dat_i,
	i3_wb_dat_o,
	i3_wb_ack_o,
	i3_wb_err_o,

	i4_wb_cyc_i,
	i4_wb_stb_i,
	i4_wb_adr_i,
	i4_wb_sel_i,
	i4_wb_we_i,
	i4_wb_dat_i,
	i4_wb_dat_o,
	i4_wb_ack_o,
	i4_wb_err_o,

	i5_wb_cyc_i,
	i5_wb_stb_i,
	i5_wb_adr_i,
	i5_wb_sel_i,
	i5_wb_we_i,
	i5_wb_dat_i,
	i5_wb_dat_o,
	i5_wb_ack_o,
	i5_wb_err_o,

	i6_wb_cyc_i,
	i6_wb_stb_i,
	i6_wb_adr_i,
	i6_wb_sel_i,
	i6_wb_we_i,
	i6_wb_dat_i,
	i6_wb_dat_o,
	i6_wb_ack_o,
	i6_wb_err_o,

	i7_wb_cyc_i,
	i7_wb_stb_i,
	i7_wb_adr_i,
	i7_wb_sel_i,
	i7_wb_we_i,
	i7_wb_dat_i,
	i7_wb_dat_o,
	i7_wb_ack_o,
	i7_wb_err_o,

	t0_wb_cyc_o,
	t0_wb_stb_o,
	t0_wb_adr_o,
	t0_wb_sel_o,
	t0_wb_we_o,
	t0_wb_dat_o,
	t0_wb_dat_i,
	t0_wb_ack_i,
	t0_wb_err_i

);

//
// Parameters
//
parameter		t0_addr_w = 2;
parameter		t0_addr = 2'b00;

parameter		multitarg = 1'b0;

parameter		t17_addr_w = 2;    // Only used if multitarg == 1.
parameter		t17_addr = 2'b00;  // Only used if multitarg == 1.

//
// I/O Ports
//
input			wb_clk_i;
input			wb_rst_i;

//
// WB slave i/f connecting initiator 0
//
input			i0_wb_cyc_i;
input			i0_wb_stb_i;
input	[`TC_AW-1:0]	i0_wb_adr_i;
input	[`TC_BSW-1:0]	i0_wb_sel_i;
input			i0_wb_we_i;
input	[`TC_DW-1:0]	i0_wb_dat_i;
output	[`TC_DW-1:0]	i0_wb_dat_o;
output			i0_wb_ack_o;
output			i0_wb_err_o;

//
// WB slave i/f connecting initiator 1
//
input			i1_wb_cyc_i;
input			i1_wb_stb_i;
input	[`TC_AW-1:0]	i1_wb_adr_i;
input	[`TC_BSW-1:0]	i1_wb_sel_i;
input			i1_wb_we_i;
input	[`TC_DW-1:0]	i1_wb_dat_i;
output	[`TC_DW-1:0]	i1_wb_dat_o;
output			i1_wb_ack_o;
output			i1_wb_err_o;

//
// WB slave i/f connecting initiator 2
//
input			i2_wb_cyc_i;
input			i2_wb_stb_i;
input	[`TC_AW-1:0]	i2_wb_adr_i;
input	[`TC_BSW-1:0]	i2_wb_sel_i;
input			i2_wb_we_i;
input	[`TC_DW-1:0]	i2_wb_dat_i;
output	[`TC_DW-1:0]	i2_wb_dat_o;
output			i2_wb_ack_o;
output			i2_wb_err_o;

//
// WB slave i/f connecting initiator 3
//
input			i3_wb_cyc_i;
input			i3_wb_stb_i;
input	[`TC_AW-1:0]	i3_wb_adr_i;
input	[`TC_BSW-1:0]	i3_wb_sel_i;
input			i3_wb_we_i;
input	[`TC_DW-1:0]	i3_wb_dat_i;
output	[`TC_DW-1:0]	i3_wb_dat_o;
output			i3_wb_ack_o;
output			i3_wb_err_o;

//
// WB slave i/f connecting initiator 4
//
input			i4_wb_cyc_i;
input			i4_wb_stb_i;
input	[`TC_AW-1:0]	i4_wb_adr_i;
input	[`TC_BSW-1:0]	i4_wb_sel_i;
input			i4_wb_we_i;
input	[`TC_DW-1:0]	i4_wb_dat_i;
output	[`TC_DW-1:0]	i4_wb_dat_o;
output			i4_wb_ack_o;
output			i4_wb_err_o;

//
// WB slave i/f connecting initiator 5
//
input			i5_wb_cyc_i;
input			i5_wb_stb_i;
input	[`TC_AW-1:0]	i5_wb_adr_i;
input	[`TC_BSW-1:0]	i5_wb_sel_i;
input			i5_wb_we_i;
input	[`TC_DW-1:0]	i5_wb_dat_i;
output	[`TC_DW-1:0]	i5_wb_dat_o;
output			i5_wb_ack_o;
output			i5_wb_err_o;

//
// WB slave i/f connecting initiator 6
//
input			i6_wb_cyc_i;
input			i6_wb_stb_i;
input	[`TC_AW-1:0]	i6_wb_adr_i;
input	[`TC_BSW-1:0]	i6_wb_sel_i;
input			i6_wb_we_i;
input	[`TC_DW-1:0]	i6_wb_dat_i;
output	[`TC_DW-1:0]	i6_wb_dat_o;
output			i6_wb_ack_o;
output			i6_wb_err_o;

//
// WB slave i/f connecting initiator 7
//
input			i7_wb_cyc_i;
input			i7_wb_stb_i;
input	[`TC_AW-1:0]	i7_wb_adr_i;
input	[`TC_BSW-1:0]	i7_wb_sel_i;
input			i7_wb_we_i;
input	[`TC_DW-1:0]	i7_wb_dat_i;
output	[`TC_DW-1:0]	i7_wb_dat_o;
output			i7_wb_ack_o;
output			i7_wb_err_o;

//
// WB master i/f connecting target
//
output			t0_wb_cyc_o;
output			t0_wb_stb_o;
output	[`TC_AW-1:0]	t0_wb_adr_o;
output	[`TC_BSW-1:0]	t0_wb_sel_o;
output			t0_wb_we_o;
output	[`TC_DW-1:0]	t0_wb_dat_o;
input	[`TC_DW-1:0]	t0_wb_dat_i;
input			t0_wb_ack_i;
input			t0_wb_err_i;

//
// Internal wires & registers
//
wire	[`TC_IIN_W-1:0]	i0_in, i1_in,
			i2_in, i3_in,
			i4_in, i5_in,
			i6_in, i7_in;
wire	[`TC_TIN_W-1:0]	i0_out, i1_out,
			i2_out, i3_out,
			i4_out, i5_out,
			i6_out, i7_out;
wire	[`TC_IIN_W-1:0]	t0_out;
wire	[`TC_TIN_W-1:0]	t0_in;
wire	[7:0]		req_i;
wire	[2:0]		req_won;
reg			req_cont;
reg	[2:0]		req_r;

//
// Group WB initiator 0 i/f inputs and outputs
//
assign i0_in = {i0_wb_cyc_i, i0_wb_stb_i, i0_wb_adr_i,
		i0_wb_sel_i, i0_wb_we_i, i0_wb_dat_i};
assign {i0_wb_dat_o, i0_wb_ack_o, i0_wb_err_o} = i0_out;

//
// Group WB initiator 1 i/f inputs and outputs
//
assign i1_in = {i1_wb_cyc_i, i1_wb_stb_i, i1_wb_adr_i,
		i1_wb_sel_i, i1_wb_we_i, i1_wb_dat_i};
assign {i1_wb_dat_o, i1_wb_ack_o, i1_wb_err_o} = i1_out;

//
// Group WB initiator 2 i/f inputs and outputs
//
assign i2_in = {i2_wb_cyc_i, i2_wb_stb_i, i2_wb_adr_i,
		i2_wb_sel_i, i2_wb_we_i, i2_wb_dat_i};
assign {i2_wb_dat_o, i2_wb_ack_o, i2_wb_err_o} = i2_out;

//
// Group WB initiator 3 i/f inputs and outputs
//
assign i3_in = {i3_wb_cyc_i, i3_wb_stb_i, i3_wb_adr_i,
		i3_wb_sel_i, i3_wb_we_i, i3_wb_dat_i};
assign {i3_wb_dat_o, i3_wb_ack_o, i3_wb_err_o} = i3_out;

//
// Group WB initiator 4 i/f inputs and outputs
//
assign i4_in = {i4_wb_cyc_i, i4_wb_stb_i, i4_wb_adr_i,
		i4_wb_sel_i, i4_wb_we_i, i4_wb_dat_i};
assign {i4_wb_dat_o, i4_wb_ack_o, i4_wb_err_o} = i4_out;

//
// Group WB initiator 5 i/f inputs and outputs
//
assign i5_in = {i5_wb_cyc_i, i5_wb_stb_i, i5_wb_adr_i,
		i5_wb_sel_i, i5_wb_we_i, i5_wb_dat_i};
assign {i5_wb_dat_o, i5_wb_ack_o, i5_wb_err_o} = i5_out;

//
// Group WB initiator 6 i/f inputs and outputs
//
assign i6_in = {i6_wb_cyc_i, i6_wb_stb_i, i6_wb_adr_i,
		i6_wb_sel_i, i6_wb_we_i, i6_wb_dat_i};
assign {i6_wb_dat_o, i6_wb_ack_o, i6_wb_err_o} = i6_out;

//
// Group WB initiator 7 i/f inputs and outputs
//
assign i7_in = {i7_wb_cyc_i, i7_wb_stb_i, i7_wb_adr_i,
		i7_wb_sel_i, i7_wb_we_i, i7_wb_dat_i};
assign {i7_wb_dat_o, i7_wb_ack_o, i7_wb_err_o} = i7_out;

//
// Group WB target 0 i/f inputs and outputs
//
assign {t0_wb_cyc_o, t0_wb_stb_o, t0_wb_adr_o,
		t0_wb_sel_o, t0_wb_we_o, t0_wb_dat_o} = t0_out;
assign t0_in = {t0_wb_dat_i, t0_wb_ack_i, t0_wb_err_i};

//
// Assign to WB initiator i/f outputs
//
// Either inputs from the target are assigned or zeros.
//
assign i0_out = (req_won == 3'd0) ? t0_in : {`TC_TIN_W{1'b0}};
assign i1_out = (req_won == 3'd1) ? t0_in : {`TC_TIN_W{1'b0}};
assign i2_out = (req_won == 3'd2) ? t0_in : {`TC_TIN_W{1'b0}};
assign i3_out = (req_won == 3'd3) ? t0_in : {`TC_TIN_W{1'b0}};
assign i4_out = (req_won == 3'd4) ? t0_in : {`TC_TIN_W{1'b0}};
assign i5_out = (req_won == 3'd5) ? t0_in : {`TC_TIN_W{1'b0}};
assign i6_out = (req_won == 3'd6) ? t0_in : {`TC_TIN_W{1'b0}};
assign i7_out = (req_won == 3'd7) ? t0_in : {`TC_TIN_W{1'b0}};

//
// Assign to WB target i/f outputs
//
// Assign inputs from initiator to target outputs according to
// which initiator has won. If there is no request for the target,
// assign zeros.
//
assign t0_out = (req_won == 3'd0) ? i0_in :
                (req_won == 3'd1) ? i1_in :
                (req_won == 3'd2) ? i2_in :
                (req_won == 3'd3) ? i3_in :
                (req_won == 3'd4) ? i4_in :
                (req_won == 3'd5) ? i5_in :
                (req_won == 3'd6) ? i6_in :
                (req_won == 3'd7) ? i7_in : {`TC_IIN_W{1'b0}};

//
// Determine if the initiator has the address of one of the targets.
//
assign req_i[0] = i0_wb_cyc_i &
	((i0_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
	 multitarg & (i0_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
assign req_i[1] = i1_wb_cyc_i &
	((i1_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
	 multitarg & (i1_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
assign req_i[2] = i2_wb_cyc_i &
	((i2_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
	 multitarg & (i2_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
assign req_i[3] = i3_wb_cyc_i &
	((i3_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
	 multitarg & (i3_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
assign req_i[4] = i4_wb_cyc_i &
	((i4_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
	 multitarg & (i4_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
assign req_i[5] = i5_wb_cyc_i &
	((i5_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
	 multitarg & (i5_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
assign req_i[6] = i6_wb_cyc_i &
	((i6_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
	 multitarg & (i6_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));
assign req_i[7] = i7_wb_cyc_i &
	((i7_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr) |
	 multitarg & (i7_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t17_addr));

//
// Determine who gets current access to the target.
//
// If current initiator still asserts request, do nothing
// (keep current initiator).
// Otherwise check each initiator's request, starting from initiator 0
// (highest priority).
// If there is no requests from initiators, park initiator 0.
//
assign req_won = req_cont ? req_r :
		 req_i[0] ? 3'd0 :
		 req_i[1] ? 3'd1 :
		 req_i[2] ? 3'd2 :
		 req_i[3] ? 3'd3 :
		 req_i[4] ? 3'd4 :
		 req_i[5] ? 3'd5 :
		 req_i[6] ? 3'd6 :
		 req_i[7] ? 3'd7 : 3'd0;

//
// Check if current initiator still wants access to the target and if
// it does, assert req_cont.
//
always @(req_r or req_i)
     `UNIQUE case (req_r)	// synopsys parallel_case
		3'd0: req_cont = req_i[0];
		3'd1: req_cont = req_i[1];
		3'd2: req_cont = req_i[2];
		3'd3: req_cont = req_i[3];
		3'd4: req_cont = req_i[4];
		3'd5: req_cont = req_i[5];
		3'd6: req_cont = req_i[6];
		3'd7: req_cont = req_i[7];
	endcase

//
// Register who has current access to the target.
//

initial
  begin
     // In case the reset signal is not asserted at the beginning, initialise this module properly here.
     req_r = 3'd0;
  end

always @(posedge wb_clk_i)
	if (wb_rst_i)
		req_r <= 3'd0;
	else
		req_r <= req_won;

endmodule
