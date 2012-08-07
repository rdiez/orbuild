//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Xess Traffic Cop                                            ////
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

`include "minsoc_tc_defines.v"

//
// Single initiator to multiple targets
//
module minsoc_tc_si_to_mt (

	i0_wb_cyc_i,
	i0_wb_stb_i,
	i0_wb_adr_i,
	i0_wb_sel_i,
	i0_wb_we_i,
	i0_wb_dat_i,
	i0_wb_dat_o,
	i0_wb_ack_o,
	i0_wb_err_o,

	t0_wb_cyc_o,
	t0_wb_stb_o,
	t0_wb_adr_o,
	t0_wb_sel_o,
	t0_wb_we_o,
	t0_wb_dat_o,
	t0_wb_dat_i,
	t0_wb_ack_i,
	t0_wb_err_i,

	t1_wb_cyc_o,
	t1_wb_stb_o,
	t1_wb_adr_o,
	t1_wb_sel_o,
	t1_wb_we_o,
	t1_wb_dat_o,
	t1_wb_dat_i,
	t1_wb_ack_i,
	t1_wb_err_i,

	t2_wb_cyc_o,
	t2_wb_stb_o,
	t2_wb_adr_o,
	t2_wb_sel_o,
	t2_wb_we_o,
	t2_wb_dat_o,
	t2_wb_dat_i,
	t2_wb_ack_i,
	t2_wb_err_i,

	t3_wb_cyc_o,
	t3_wb_stb_o,
	t3_wb_adr_o,
	t3_wb_sel_o,
	t3_wb_we_o,
	t3_wb_dat_o,
	t3_wb_dat_i,
	t3_wb_ack_i,
	t3_wb_err_i,

	t4_wb_cyc_o,
	t4_wb_stb_o,
	t4_wb_adr_o,
	t4_wb_sel_o,
	t4_wb_we_o,
	t4_wb_dat_o,
	t4_wb_dat_i,
	t4_wb_ack_i,
	t4_wb_err_i,

	t5_wb_cyc_o,
	t5_wb_stb_o,
	t5_wb_adr_o,
	t5_wb_sel_o,
	t5_wb_we_o,
	t5_wb_dat_o,
	t5_wb_dat_i,
	t5_wb_ack_i,
	t5_wb_err_i,

	t6_wb_cyc_o,
	t6_wb_stb_o,
	t6_wb_adr_o,
	t6_wb_sel_o,
	t6_wb_we_o,
	t6_wb_dat_o,
	t6_wb_dat_i,
	t6_wb_ack_i,
	t6_wb_err_i,

	t7_wb_cyc_o,
	t7_wb_stb_o,
	t7_wb_adr_o,
	t7_wb_sel_o,
	t7_wb_we_o,
	t7_wb_dat_o,
	t7_wb_dat_i,
	t7_wb_ack_i,
	t7_wb_err_i

);

//
// Parameters
//
parameter		t0_addr_w = 3;
parameter		t0_addr = 3'd0;
parameter		t17_addr_w = 3;
parameter		t1_addr = 3'd1;
parameter		t2_addr = 3'd2;
parameter		t3_addr = 3'd3;
parameter		t4_addr = 3'd4;
parameter		t5_addr = 3'd5;
parameter		t6_addr = 3'd6;
parameter		t7_addr = 3'd7;

//
// I/O Ports
//

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
// WB master i/f connecting target 0
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
// WB master i/f connecting target 1
//
output			t1_wb_cyc_o;
output			t1_wb_stb_o;
output	[`TC_AW-1:0]	t1_wb_adr_o;
output	[`TC_BSW-1:0]	t1_wb_sel_o;
output			t1_wb_we_o;
output	[`TC_DW-1:0]	t1_wb_dat_o;
input	[`TC_DW-1:0]	t1_wb_dat_i;
input			t1_wb_ack_i;
input			t1_wb_err_i;

//
// WB master i/f connecting target 2
//
output			t2_wb_cyc_o;
output			t2_wb_stb_o;
output	[`TC_AW-1:0]	t2_wb_adr_o;
output	[`TC_BSW-1:0]	t2_wb_sel_o;
output			t2_wb_we_o;
output	[`TC_DW-1:0]	t2_wb_dat_o;
input	[`TC_DW-1:0]	t2_wb_dat_i;
input			t2_wb_ack_i;
input			t2_wb_err_i;

//
// WB master i/f connecting target 3
//
output			t3_wb_cyc_o;
output			t3_wb_stb_o;
output	[`TC_AW-1:0]	t3_wb_adr_o;
output	[`TC_BSW-1:0]	t3_wb_sel_o;
output			t3_wb_we_o;
output	[`TC_DW-1:0]	t3_wb_dat_o;
input	[`TC_DW-1:0]	t3_wb_dat_i;
input			t3_wb_ack_i;
input			t3_wb_err_i;

//
// WB master i/f connecting target 4
//
output			t4_wb_cyc_o;
output			t4_wb_stb_o;
output	[`TC_AW-1:0]	t4_wb_adr_o;
output	[`TC_BSW-1:0]	t4_wb_sel_o;
output			t4_wb_we_o;
output	[`TC_DW-1:0]	t4_wb_dat_o;
input	[`TC_DW-1:0]	t4_wb_dat_i;
input			t4_wb_ack_i;
input			t4_wb_err_i;

//
// WB master i/f connecting target 5
//
output			t5_wb_cyc_o;
output			t5_wb_stb_o;
output	[`TC_AW-1:0]	t5_wb_adr_o;
output	[`TC_BSW-1:0]	t5_wb_sel_o;
output			t5_wb_we_o;
output	[`TC_DW-1:0]	t5_wb_dat_o;
input	[`TC_DW-1:0]	t5_wb_dat_i;
input			t5_wb_ack_i;
input			t5_wb_err_i;

//
// WB master i/f connecting target 6
//
output			t6_wb_cyc_o;
output			t6_wb_stb_o;
output	[`TC_AW-1:0]	t6_wb_adr_o;
output	[`TC_BSW-1:0]	t6_wb_sel_o;
output			t6_wb_we_o;
output	[`TC_DW-1:0]	t6_wb_dat_o;
input	[`TC_DW-1:0]	t6_wb_dat_i;
input			t6_wb_ack_i;
input			t6_wb_err_i;

//
// WB master i/f connecting target 7
//
output			t7_wb_cyc_o;
output			t7_wb_stb_o;
output	[`TC_AW-1:0]	t7_wb_adr_o;
output	[`TC_BSW-1:0]	t7_wb_sel_o;
output			t7_wb_we_o;
output	[`TC_DW-1:0]	t7_wb_dat_o;
input	[`TC_DW-1:0]	t7_wb_dat_i;
input			t7_wb_ack_i;
input			t7_wb_err_i;

//
// Internal wires & registers
//
wire	[`TC_IIN_W-1:0]	i0_in;
wire	[`TC_TIN_W-1:0]	i0_out;
wire	[`TC_IIN_W-1:0]	t0_out, t1_out,
			t2_out, t3_out,
			t4_out, t5_out,
			t6_out, t7_out;
wire	[`TC_TIN_W-1:0]	t0_in, t1_in,
			t2_in, t3_in,
			t4_in, t5_in,
			t6_in, t7_in;
wire	[7:0]		req_t;

//
// Group WB initiator 0 i/f inputs and outputs
//
assign i0_in = {i0_wb_cyc_i, i0_wb_stb_i, i0_wb_adr_i,
		i0_wb_sel_i, i0_wb_we_i, i0_wb_dat_i};
assign {i0_wb_dat_o, i0_wb_ack_o, i0_wb_err_o} = i0_out;

//
// Group WB target 0 i/f inputs and outputs
//
assign {t0_wb_cyc_o, t0_wb_stb_o, t0_wb_adr_o,
		t0_wb_sel_o, t0_wb_we_o, t0_wb_dat_o} = t0_out;
assign t0_in = {t0_wb_dat_i, t0_wb_ack_i, t0_wb_err_i};

//
// Group WB target 1 i/f inputs and outputs
//
assign {t1_wb_cyc_o, t1_wb_stb_o, t1_wb_adr_o,
		t1_wb_sel_o, t1_wb_we_o, t1_wb_dat_o} = t1_out;
assign t1_in = {t1_wb_dat_i, t1_wb_ack_i, t1_wb_err_i};

//
// Group WB target 2 i/f inputs and outputs
//
assign {t2_wb_cyc_o, t2_wb_stb_o, t2_wb_adr_o,
		t2_wb_sel_o, t2_wb_we_o, t2_wb_dat_o} = t2_out;
assign t2_in = {t2_wb_dat_i, t2_wb_ack_i, t2_wb_err_i};

//
// Group WB target 3 i/f inputs and outputs
//
assign {t3_wb_cyc_o, t3_wb_stb_o, t3_wb_adr_o,
		t3_wb_sel_o, t3_wb_we_o, t3_wb_dat_o} = t3_out;
assign t3_in = {t3_wb_dat_i, t3_wb_ack_i, t3_wb_err_i};

//
// Group WB target 4 i/f inputs and outputs
//
assign {t4_wb_cyc_o, t4_wb_stb_o, t4_wb_adr_o,
		t4_wb_sel_o, t4_wb_we_o, t4_wb_dat_o} = t4_out;
assign t4_in = {t4_wb_dat_i, t4_wb_ack_i, t4_wb_err_i};

//
// Group WB target 5 i/f inputs and outputs
//
assign {t5_wb_cyc_o, t5_wb_stb_o, t5_wb_adr_o,
		t5_wb_sel_o, t5_wb_we_o, t5_wb_dat_o} = t5_out;
assign t5_in = {t5_wb_dat_i, t5_wb_ack_i, t5_wb_err_i};

//
// Group WB target 6 i/f inputs and outputs
//
assign {t6_wb_cyc_o, t6_wb_stb_o, t6_wb_adr_o,
		t6_wb_sel_o, t6_wb_we_o, t6_wb_dat_o} = t6_out;
assign t6_in = {t6_wb_dat_i, t6_wb_ack_i, t6_wb_err_i};

//
// Group WB target 7 i/f inputs and outputs
//
assign {t7_wb_cyc_o, t7_wb_stb_o, t7_wb_adr_o,
		t7_wb_sel_o, t7_wb_we_o, t7_wb_dat_o} = t7_out;
assign t7_in = {t7_wb_dat_i, t7_wb_ack_i, t7_wb_err_i};

//
// Assign to WB target i/f outputs
//
// Either inputs from the initiator are assigned or zeros.
//
assign t0_out = req_t[0] ? i0_in : {`TC_IIN_W{1'b0}};
assign t1_out = req_t[1] ? i0_in : {`TC_IIN_W{1'b0}};
assign t2_out = req_t[2] ? i0_in : {`TC_IIN_W{1'b0}};
assign t3_out = req_t[3] ? i0_in : {`TC_IIN_W{1'b0}};
assign t4_out = req_t[4] ? i0_in : {`TC_IIN_W{1'b0}};
assign t5_out = req_t[5] ? i0_in : {`TC_IIN_W{1'b0}};
assign t6_out = req_t[6] ? i0_in : {`TC_IIN_W{1'b0}};
assign t7_out = req_t[7] ? i0_in : {`TC_IIN_W{1'b0}};

//
// Assign to WB initiator i/f outputs
//
// Assign inputs from target to initiator outputs according to
// which target is accessed. If there is no request for a target,
// assign zeros.
//
assign i0_out = req_t[0] ? t0_in :
		req_t[1] ? t1_in :
		req_t[2] ? t2_in :
		req_t[3] ? t3_in :
		req_t[4] ? t4_in :
		req_t[5] ? t5_in :
		req_t[6] ? t6_in :
		req_t[7] ? t7_in : {`TC_TIN_W{1'b0}};

//
// Determine which target is being accessed.
//
assign req_t[0] = i0_wb_cyc_i & (i0_wb_adr_i[`TC_AW-1:`TC_AW-t0_addr_w] == t0_addr);
assign req_t[1] = i0_wb_cyc_i & (i0_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t1_addr);
assign req_t[2] = i0_wb_cyc_i & (i0_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t2_addr);
assign req_t[3] = i0_wb_cyc_i & (i0_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t3_addr);
assign req_t[4] = i0_wb_cyc_i & (i0_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t4_addr);
assign req_t[5] = i0_wb_cyc_i & (i0_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t5_addr);
assign req_t[6] = i0_wb_cyc_i & (i0_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t6_addr);
assign req_t[7] = i0_wb_cyc_i & (i0_wb_adr_i[`TC_AW-1:`TC_AW-t17_addr_w] == t7_addr);

endmodule	
