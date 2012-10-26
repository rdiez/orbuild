/* Simple Wishbone switch, many masters to many slaves, just one internal bus.

   About master priority:

     If two masters request the bus at the same time, the one with the lowest index
     has the highest priority. At the end of each Wishbone transaction, if another
     master with a higher priority comes in, it will get the bus,
     and the others will have to wait. That is, a master can lose the bus
     in the middle of a cycle between consecutive Wishbone transactions,
     even if it keeps its wb_cyc signal asserted between the transactions. Therefore,
     to a low-priority master, some transactions will seem to last a long time.

     The Wishbone B4 specification states that a master should not keep its wb_cyc signal
     asserted all the time in order to prevent possible arbitration problems. This advice
     would lead to unnecessary wait states on the CPU Wishbone interface, therefore
     I have decided to let the Wishbone switch interrupt a chain of transfers whenever
     a higher-priority master comes in.

   About the default slave:

     Slave 0 is the default: if no other slave is responsible for a given Wishbone address,
     that master will get the transaction.
     Having a default slave allows the chaining of Wishbone switches.

     The default master should fully decode the address and issue a bus error for all invalid ones.
     Otherwise, the CPU may hang when trying to access an invalid address.

   About adding masters or slaves:

     Unfortunately, adding masters or slaves must be done manually by editing the source code,
     but it should be pretty straightforward to do.

     Remember to update CURRENT_MASTER_WIDTH if necessary.


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


module simple_wishbone_switch
  #(
    parameter DW = 32,
    parameter AW = 32,
    parameter SELW = 4,
    parameter SLAVE_1_ADDR_PREFIX = 8'h01,
    parameter SLAVE_2_ADDR_PREFIX = 8'h02,

    parameter ENABLE_TRACING = 0,
    parameter TRACE_PREFIX = "Wishbone Switch: "
   )
  (
   input wire            wb_clk_i,
   input wire            wb_rst_i,

   // Master interfaces.

   // Master 0 has the highest priority.
   input wire            m0_wb_cyc_i,
   input wire            m0_wb_stb_i,
   input wire [AW-1:0]   m0_wb_adr_i,
   input wire [SELW-1:0] m0_wb_sel_i,
   input wire            m0_wb_we_i,
   input wire [DW-1:0]   m0_wb_dat_i,
   output reg [DW-1:0]   m0_wb_dat_o,
   output reg            m0_wb_ack_o,
   output reg            m0_wb_err_o,

   input wire            m1_wb_cyc_i,
   input wire            m1_wb_stb_i,
   input wire [AW-1:0]   m1_wb_adr_i,
   input wire [SELW-1:0] m1_wb_sel_i,
   input wire            m1_wb_we_i,
   input wire [DW-1:0]   m1_wb_dat_i,
   output reg [DW-1:0]   m1_wb_dat_o,
   output reg            m1_wb_ack_o,
   output reg            m1_wb_err_o,

   // Slave interfaces.

   // Slave 0 is the default slave.
   output reg            s0_wb_cyc_o,
   output reg            s0_wb_stb_o,
   output reg [AW-1:0]   s0_wb_adr_o,
   output reg [SELW-1:0] s0_wb_sel_o,
   output reg            s0_wb_we_o,
   output reg [DW-1:0]   s0_wb_dat_o,
   input wire [DW-1:0]   s0_wb_dat_i,
   input wire            s0_wb_ack_i,
   input wire            s0_wb_err_i,

   output reg            s1_wb_cyc_o,
   output reg            s1_wb_stb_o,
   output reg [AW-1:0]   s1_wb_adr_o,
   output reg [SELW-1:0] s1_wb_sel_o,
   output reg            s1_wb_we_o,
   output reg [DW-1:0]   s1_wb_dat_o,
   input wire [DW-1:0]   s1_wb_dat_i,
   input wire            s1_wb_ack_i,
   input wire            s1_wb_err_i,

   output reg            s2_wb_cyc_o,
   output reg            s2_wb_stb_o,
   output reg [AW-1:0]   s2_wb_adr_o,
   output reg [SELW-1:0] s2_wb_sel_o,
   output reg            s2_wb_we_o,
   output reg [DW-1:0]   s2_wb_dat_o,
   input wire [DW-1:0]   s2_wb_dat_i,
   input wire            s2_wb_ack_i,
   input wire            s2_wb_err_i
  );


   // This 'always' block calculates who the next master should be.

   localparam CURRENT_MASTER_WIDTH = 1;
   localparam DEFAULT_MASTER = 0;
   reg at_least_one_master_is_requesting;
   reg [CURRENT_MASTER_WIDTH-1:0] next_master;

   always @( * )
     begin
        at_least_one_master_is_requesting = 1;

        // We could also look at the mX_wb_stb_i signals.

        case ( 1 )
          m0_wb_cyc_i:  next_master = 0;
          m1_wb_cyc_i:  next_master = 1;
          default:
            begin
               // Default to master 0 when no master is requesting.
               next_master = DEFAULT_MASTER;
               at_least_one_master_is_requesting = 0;
            end
        endcase
     end


   // This 'always' block routes the right master to the right slave.
   reg [CURRENT_MASTER_WIDTH-1:0] current_master;

   reg prevent_changing_master;  // Keep the current master if a bus transaction is taking place.

   // Central switch lines.
   reg            selm_wb_stb;
   reg [AW-1:0]   selm_wb_adr;
   reg [SELW-1:0] selm_wb_sel;
   reg            selm_wb_we;
   reg [DW-1:0]   selm_wb_dat_master_to_slave;
   reg [DW-1:0]   selm_wb_dat_slave_to_master;
   reg            selm_wb_ack;
   reg            selm_wb_err;

   always @( * )
     begin
        if ( !prevent_changing_master )
          begin
             current_master = next_master;
          end

        // By default, all slaves are disconnected from the central switch.

        s0_wb_cyc_o = 0;  // Only the CYC signal is important.
        s0_wb_stb_o = 1'bx;
        s0_wb_adr_o = {AW{1'bx}};
        s0_wb_sel_o = {SELW{1'bx}};
        s0_wb_we_o  = 1'bx;
        s0_wb_dat_o = {DW{1'bx}};

        s1_wb_cyc_o = 0;  // Only the CYC signal is important.
        s1_wb_stb_o = 1'bx;
        s1_wb_adr_o = {AW{1'bx}};
        s1_wb_sel_o = {SELW{1'bx}};
        s1_wb_we_o  = 1'bx;
        s1_wb_dat_o = {DW{1'bx}};

        s2_wb_cyc_o = 0;  // Only the CYC signal is important.
        s2_wb_stb_o = 1'bx;
        s2_wb_adr_o = {AW{1'bx}};
        s2_wb_sel_o = {SELW{1'bx}};
        s2_wb_we_o  = 1'bx;
        s2_wb_dat_o = {DW{1'bx}};


        // By default, all masters are disconnected from the central switch.
        // If any are issuing a bus request, they should get ack == err == 0
        // until they get hold of the bus and a slave is connected.

        m0_wb_ack_o = 1'b0;
        m0_wb_err_o = 1'b0;
        m0_wb_dat_o = {DW{1'bx}};

        m1_wb_ack_o = 1'b0;
        m1_wb_err_o = 1'b0;
        m1_wb_dat_o = {DW{1'bx}};


        // Route the current master's inputs to the central exchange.

        case ( current_master )
          0:
            begin
               selm_wb_stb = m0_wb_stb_i;
               selm_wb_adr = m0_wb_adr_i;
               selm_wb_sel = m0_wb_sel_i;
               selm_wb_we  = m0_wb_we_i;
               selm_wb_dat_master_to_slave = m0_wb_dat_i;
            end
          1:
            begin
               selm_wb_stb = m1_wb_stb_i;
               selm_wb_adr = m1_wb_adr_i;
               selm_wb_sel = m1_wb_sel_i;
               selm_wb_we  = m1_wb_we_i;
               selm_wb_dat_master_to_slave = m1_wb_dat_i;
            end

          default:
            begin
               // $display( "ERROR: Invalid current_master value of %d", current_master );
               `ASSERT_FALSE;
            end
        endcase


        // Route the current slave's inputs to the central exchange.

        case ( selm_wb_adr[31:24] )
          SLAVE_1_ADDR_PREFIX:
            begin
               selm_wb_ack = s1_wb_ack_i;
               selm_wb_err = s1_wb_err_i;
               selm_wb_dat_slave_to_master = s1_wb_dat_i;
            end
          SLAVE_2_ADDR_PREFIX:
            begin
               selm_wb_ack = s2_wb_ack_i;
               selm_wb_err = s2_wb_err_i;
               selm_wb_dat_slave_to_master = s2_wb_dat_i;
            end

          default:
            begin
               // Slave 0 is the default.
               selm_wb_ack = s0_wb_ack_i;
               selm_wb_err = s0_wb_err_i;
               selm_wb_dat_slave_to_master = s0_wb_dat_i;
            end
        endcase


        // Route the central exchange to the current master's outputs.
        case ( current_master )
          0:
            begin
               m0_wb_dat_o = selm_wb_dat_slave_to_master;
               m0_wb_ack_o = selm_wb_ack;
               m0_wb_err_o = selm_wb_err;
            end
          1:
            begin
               m1_wb_dat_o = selm_wb_dat_slave_to_master;
               m1_wb_ack_o = selm_wb_ack;
               m1_wb_err_o = selm_wb_err;
            end

          default:
            begin
               `ASSERT_FALSE;
            end
        endcase


        // Route the central exchange to the current slave's outputs.
        case ( selm_wb_adr[31:24] )
          SLAVE_1_ADDR_PREFIX:
            begin
               s1_wb_cyc_o = 1;
               s1_wb_stb_o = selm_wb_stb;
               s1_wb_adr_o = selm_wb_adr;
               s1_wb_sel_o = selm_wb_sel;
               s1_wb_we_o =  selm_wb_we;
               s1_wb_dat_o = selm_wb_dat_master_to_slave;
            end

          SLAVE_2_ADDR_PREFIX:
            begin
               s2_wb_cyc_o = 1;
               s2_wb_stb_o = selm_wb_stb;
               s2_wb_adr_o = selm_wb_adr;
               s2_wb_sel_o = selm_wb_sel;
               s2_wb_we_o =  selm_wb_we;
               s2_wb_dat_o = selm_wb_dat_master_to_slave;
            end

          default:
            begin
               // Slave 0 is the default.
               s0_wb_cyc_o = 1;
               s0_wb_stb_o = selm_wb_stb;
               s0_wb_adr_o = selm_wb_adr;
               s0_wb_sel_o = selm_wb_sel;
               s0_wb_we_o =  selm_wb_we;
               s0_wb_dat_o = selm_wb_dat_master_to_slave;
            end
        endcase

        if ( ENABLE_TRACING )
          $display( "%sCurrent master: %d, addr: 0x%08h", TRACE_PREFIX, current_master, selm_wb_adr );
     end


   initial
     begin
        // In case the reset signal is not asserted at the beginning, initialise this module properly here.
        prevent_changing_master = 0;

        // These signals don't actually need to be initialised, but otherwise simulators like Icarus Verilog
        // or Xilinx' ISim will do one run with a value of 'x', which will trigger the asserts above.
        current_master = DEFAULT_MASTER;
        next_master = DEFAULT_MASTER;
        at_least_one_master_is_requesting = 0;
     end


   always @( posedge wb_clk_i )
     begin
         if ( ENABLE_TRACING )
           $display( "%sSwitch tick begin.", TRACE_PREFIX );

        if ( wb_rst_i )
          begin
             prevent_changing_master <= 0;
          end
        else
          begin
             if ( prevent_changing_master )
               begin
                  if ( selm_wb_ack != 0 &&
                       selm_wb_err != 0 )
                    begin
                       if ( ENABLE_TRACING )
                         $display( "%sA slave is asserting both wb_ack and wb_err at the same time, which is not allowed by the Wishbone specification.",
                                   TRACE_PREFIX );
                       `ASSERT_FALSE;
                    end

                  // A bus transaction is in place. When the slave answers, it marks the end of the transaction,
                  // so we can switch masters at the beginning of the next transaction.

                  if ( selm_wb_ack != 0 ||
                       selm_wb_err != 0 )
                    begin
                       if ( ENABLE_TRACING )
                         $display( "%sBus transaction end.", TRACE_PREFIX );
                       prevent_changing_master <= 0;
                    end
               end
             else
               begin
                  if ( at_least_one_master_is_requesting )
                    begin
                       if ( ENABLE_TRACING )
                         $display( "%sBus transaction started or in flight.", TRACE_PREFIX );
                       prevent_changing_master <= 1;
                    end
               end
          end

        if ( ENABLE_TRACING )
          $display( "%sSwitch tick end.", TRACE_PREFIX );
     end

endmodule
