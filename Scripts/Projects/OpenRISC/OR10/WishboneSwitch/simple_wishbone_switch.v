
/* Simple Wishbone switch, version 0.50 beta.

   This Wishbone switch connects many masters to many slaves, has just one internal bus,
   has a default slave that allows switch chaining, performs consistency checks during simulation.


   About master priority:

     If two masters request the bus at the same time, the one with the lowest index
     has the highest priority. At the end of each Wishbone transaction, if another
     master with a higher priority comes in, it will get the bus,
     and the others will have to wait. That is, a master can lose the bus
     in the middle of a cycle between consecutive Wishbone transactions,
     even if it keeps its wb_cyc signal asserted between the transactions. Therefore,
     to a low-priority master, some transactions may seem to last a long time.

     The Wishbone B4 specification states that a master should not keep its wb_cyc signal
     asserted all the time in order to prevent possible arbitration problems. However,
     this advice would lead to unnecessary wait states on the CPU Wishbone interface.
     Therefore,  I have decided to let the Wishbone switch interrupt a chain of transfers whenever
     a higher-priority master comes in, as described above.

     The priority interrupt logic is rather simple because the switch does not support
     Wishbone pipelining or burst transfers.


   About the default slave:

     Slave 0 is the default: if no other slave is responsible for a given Wishbone address,
     slave 0 will get the transaction request. Having a default slave allows the chaining
     of Wishbone switches.

     The default slave should fully decode the address and issue a bus error for all invalid addresses.
     Otherwise, the CPU may hang when trying to access an invalid address.


   About unused slaves:
     If you are not using a slave port and don't want to remove the port from the source code,
     you should connect the slave signals like this:
       assign unused_slave_wb_ack = 0;
       assign unused_slave_wb_err = unused_slave_wb_cyc && unused_slave_wb_stb;
     Otherwise, if a master tries to access an address on that slave, it may hang forever.


   About the consistency checks:

     This switch contains some consistency checks that may prove useful during simulation:

     1) If a master requests the bus by asserting mX_wb_cyc_i, it cannot change its mind and
        deassert it without completing at least one transaction.

     2) Check that mX_wb_cyc_i and mX_wb_stb_i are the same signal. This is not required by the standard
        and could be commented out. However, it's normally the case.

     3) A slave is only allowed to assert wb_ack or wb_err when wb_cyc and wb_stb are asserted.

     4) A slave may not assert wb_ack and wb_err at the same time.


   About adding masters or slaves:

     Unfortunately, adding masters or slaves must be done manually by editing the source code,
     but it should be pretty straightforward to do.

     Remember to update MASTER_INDEX_WIDTH and SLAVE_INDEX_WIDTH if necessary.


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
    parameter SELW = 4,  // For the wb_sel_i signals.

    // Slave 0 is the default if an address is not handled by any other slave.
    parameter SLAVE_1_ADDR_PREFIX = 8'h01,
    parameter SLAVE_2_ADDR_PREFIX = 8'h02,

    parameter ENABLE_TRACING = 0,
    parameter ENABLE_CONSISTENCY_CHECKS = 1,
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


   localparam SLAVE_INDEX_WIDTH = 2;

   localparam MASTER_INDEX_WIDTH = 1;
   localparam MASTER_COUNT = 2;

   localparam DEFAULT_MASTER = 0;
   localparam DEFAULT_SLAVE  = 0;

   // This 'always' block calculates which master has the highest priority, among all those who are requesting the bus.

   reg at_least_one_master_is_requesting;
   reg [MASTER_INDEX_WIDTH-1:0] highest_priority_requesting_master;

   always @(*)
     begin
        at_least_one_master_is_requesting = 1;

        // We could also look at the mX_wb_stb_i signals.

        case ( 1 )
          m0_wb_cyc_i:  highest_priority_requesting_master = 0;
          m1_wb_cyc_i:  highest_priority_requesting_master = 1;
          default:
            begin
               // Default to master 0 when no master is requesting.
               highest_priority_requesting_master = DEFAULT_MASTER;
               at_least_one_master_is_requesting = 0;
            end
        endcase
     end


   // When a master initiates a transaction, it cannot be swapped out until the transaction finishes.
   reg                           is_master_locked;
   reg [MASTER_INDEX_WIDTH-1:0]  locked_master_index;

   reg [MASTER_INDEX_WIDTH-1:0]  master_to_connect_now;

   // Calculate which master should be connected at this point in time.
   always @(*)
     begin
        master_to_connect_now = is_master_locked ? locked_master_index : highest_priority_requesting_master;
     end


   // Central switch lines.
   reg            selm_wb_cyc;
   reg            selm_wb_stb;
   reg [AW-1:0]   selm_wb_adr;
   reg [SELW-1:0] selm_wb_sel;
   reg            selm_wb_we;
   reg [DW-1:0]   selm_wb_dat_master_to_slave;
   reg [DW-1:0]   selm_wb_dat_slave_to_master;
   reg            selm_wb_ack;
   reg            selm_wb_err;

   reg [SLAVE_INDEX_WIDTH-1:0]  slave_to_connect_now;


   // This 'always' block routes the current master's outputs to the central exchange.
   //
   // It must be separated from the next "always @(*)" block or the simulators (Icarus Verilog, Verilator)
   // will have feedback problems and slow down.

   always @(*)
     begin
        case ( master_to_connect_now )
          0:
            begin
               selm_wb_cyc = m0_wb_cyc_i;  // This could be just '= 1'.
               selm_wb_stb = m0_wb_stb_i;
               selm_wb_adr = m0_wb_adr_i;
               selm_wb_sel = m0_wb_sel_i;
               selm_wb_we  = m0_wb_we_i;
               selm_wb_dat_master_to_slave = m0_wb_dat_i;
            end
          1:
            begin
               selm_wb_cyc = m1_wb_cyc_i;  // This could be just '= 1'.
               selm_wb_stb = m1_wb_stb_i;
               selm_wb_adr = m1_wb_adr_i;
               selm_wb_sel = m1_wb_sel_i;
               selm_wb_we  = m1_wb_we_i;
               selm_wb_dat_master_to_slave = m1_wb_dat_i;
            end

          default:
            begin
               $display( "ERROR: Invalid master_to_connect_now value of %d", master_to_connect_now );
               `ASSERT_FALSE;

               selm_wb_cyc = 1'bx;
               selm_wb_stb = 1'bx;
               selm_wb_adr = {AW{1'bx}};
               selm_wb_sel = {SELW{1'bx}};
               selm_wb_we  = 1'bx;
               selm_wb_dat_master_to_slave = {DW{1'bx}};
            end
        endcase

        if ( ENABLE_TRACING )
          $display( "%sConnecting master %d.", TRACE_PREFIX, master_to_connect_now );
     end


   // This 'always' block does the rest of the routine between the current master and right slave.

   always @(*)
     begin
        // Route the current slave's outputs to the central exchange.

        case ( selm_wb_adr[31:24] )
          SLAVE_1_ADDR_PREFIX:  slave_to_connect_now = 1;
          SLAVE_2_ADDR_PREFIX:  slave_to_connect_now = 2;
          default:              slave_to_connect_now = DEFAULT_SLAVE;
        endcase

        case ( slave_to_connect_now )
          0:
            begin
               selm_wb_ack = s0_wb_ack_i;
               selm_wb_err = s0_wb_err_i;
               selm_wb_dat_slave_to_master = s0_wb_dat_i;
            end

          1:
            begin
               selm_wb_ack = s1_wb_ack_i;
               selm_wb_err = s1_wb_err_i;
               selm_wb_dat_slave_to_master = s1_wb_dat_i;
            end

          2:
            begin
               selm_wb_ack = s2_wb_ack_i;
               selm_wb_err = s2_wb_err_i;
               selm_wb_dat_slave_to_master = s2_wb_dat_i;
            end

          default:
            begin
               `ASSERT_FALSE;
               selm_wb_ack = 1'bx;
               selm_wb_err = 1'bx;
               selm_wb_dat_slave_to_master = {DW{1'bx}};
            end
        endcase


        // By default, all masters are disconnected from the central switch.
        // If any are issuing a bus request, they should get ack == err == 0
        // until they get hold of the bus and a slave is connected.

        m0_wb_ack_o = 1'b0;
        m0_wb_err_o = 1'b0;
        m0_wb_dat_o = {DW{1'bx}};

        m1_wb_ack_o = 1'b0;
        m1_wb_err_o = 1'b0;
        m1_wb_dat_o = {DW{1'bx}};

        // Route the central exchange to the current master's inputs.

        case ( master_to_connect_now )
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
               $display( "ERROR: Invalid master_to_connect_now value of %d", master_to_connect_now );
               `ASSERT_FALSE;
            end
        endcase


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


        // Route the central exchange to the current slave's inputs.

        case ( selm_wb_adr[31:24] )
          SLAVE_1_ADDR_PREFIX:
            begin
               s1_wb_cyc_o = selm_wb_cyc;
               s1_wb_stb_o = selm_wb_stb;
               s1_wb_adr_o = selm_wb_adr;
               s1_wb_sel_o = selm_wb_sel;
               s1_wb_we_o  = selm_wb_we;
               s1_wb_dat_o = selm_wb_dat_master_to_slave;
            end

          SLAVE_2_ADDR_PREFIX:
            begin
               s2_wb_cyc_o = selm_wb_cyc;
               s2_wb_stb_o = selm_wb_stb;
               s2_wb_adr_o = selm_wb_adr;
               s2_wb_sel_o = selm_wb_sel;
               s2_wb_we_o  = selm_wb_we;
               s2_wb_dat_o = selm_wb_dat_master_to_slave;
            end

          default:
            begin
               // Slave 0 is the default.
               s0_wb_cyc_o = selm_wb_cyc;
               s0_wb_stb_o = selm_wb_stb;
               s0_wb_adr_o = selm_wb_adr;
               s0_wb_sel_o = selm_wb_sel;
               s0_wb_we_o  = selm_wb_we;
               s0_wb_dat_o = selm_wb_dat_master_to_slave;
            end
        endcase

        if ( ENABLE_TRACING )
          $display( "%sConnecting slave %d for transaction address 0x%08h.",
                    TRACE_PREFIX, slave_to_connect_now, selm_wb_adr );
     end


   reg [ MASTER_COUNT - 1 : 0 ] master_must_still_be_requesting;

   task automatic check_master_request_is_consistent;

      input reg [MASTER_INDEX_WIDTH-1:0] master_index;
      input reg master_cyc;
      input reg master_stb;

      begin
         if ( !master_cyc && master_must_still_be_requesting[ master_index ] )
           begin
              $display( "%sERROR: Master %d should still be requesting the bus, but is not.",
                        TRACE_PREFIX, master_index );
              `ASSERT_FALSE;
           end

         if ( master_cyc != master_stb )
           begin
              $display( "%sERROR: master %d is asserting different values in wb_cyc and wb_stb, which is unusal. This may not be an error, so you may need to disable this check.",
                        TRACE_PREFIX, master_index );
              `ASSERT_FALSE;
           end
      end
   endtask


   task automatic check_slave_response_is_consistent;

      input reg [SLAVE_INDEX_WIDTH-1:0] slave_index;
      input reg slave_cyc;
      input reg slave_stb;
      input reg slave_ack;
      input reg slave_err;

      begin
         if ( ( !slave_cyc || !slave_stb ) && ( slave_ack || slave_err ) )
           begin
              $display( "%sERROR: Slave %d is asserting wb_ack or wb_err, but its wb_cyc and wb_stb signals are not being asserted. This may be a problem in this slave or in the current master, which may have given up before the end of the transaction.",
                        TRACE_PREFIX, slave_index );
              `ASSERT_FALSE;
           end


         if ( slave_ack && slave_err )
           begin
              $display( "%sERROR: Slave %d is asserting both wb_ack and wb_err at the same time, which is not allowed by the Wishbone specification.",
                        TRACE_PREFIX, slave_index );
              `ASSERT_FALSE;
           end
      end
   endtask


   always @( posedge wb_clk_i )
     begin
        if ( ENABLE_TRACING )
          $display( "%sClock posedge begin.", TRACE_PREFIX );

        if ( wb_rst_i )
          begin
             is_master_locked <= 0;
             locked_master_index <= {MASTER_INDEX_WIDTH{1'bx}};

             master_must_still_be_requesting <= {MASTER_COUNT{1'b0}};
          end
        else
          begin
             if ( ENABLE_CONSISTENCY_CHECKS )
               begin
                  check_master_request_is_consistent( 0, m0_wb_cyc_i, m0_wb_stb_i );
                  check_master_request_is_consistent( 1, m1_wb_cyc_i, m1_wb_stb_i );

                  if ( m0_wb_cyc_i && m0_wb_stb_i )  master_must_still_be_requesting[0] <= 1;
                  if ( m1_wb_cyc_i && m1_wb_stb_i )  master_must_still_be_requesting[1] <= 1;

                  check_slave_response_is_consistent( 0, s0_wb_cyc_o, s0_wb_stb_o, s0_wb_ack_i, s0_wb_err_i );
                  check_slave_response_is_consistent( 1, s1_wb_cyc_o, s1_wb_stb_o, s1_wb_ack_i, s1_wb_err_i );
                  check_slave_response_is_consistent( 2, s2_wb_cyc_o, s2_wb_stb_o, s2_wb_ack_i, s2_wb_err_i );
               end

             if ( is_master_locked )
               begin
                  // A bus transaction is taking place.

                  if ( locked_master_index != master_to_connect_now )
                    begin
                       `ASSERT_FALSE;
                    end

                  if ( ENABLE_TRACING )
                    $display( "%sBus transaction in flight, master %d is connected to slave %d, address is 0x%08h.",
                              TRACE_PREFIX, locked_master_index, slave_to_connect_now, selm_wb_adr );

                  // When the slave answers, it marks the end of the transaction,
                  // so we can switch masters at the beginning of the next transaction if necessary.
                  if ( selm_wb_ack != 0 ||
                       selm_wb_err != 0 )
                    begin
                       if ( ENABLE_TRACING )
                         $display( "%sBus transaction ended.", TRACE_PREFIX );

                       is_master_locked <= 0;
                       locked_master_index <= {MASTER_INDEX_WIDTH{1'bx}};

                       master_must_still_be_requesting[ locked_master_index ] <= 0;
                    end
               end
             else
               begin
                  if ( at_least_one_master_is_requesting )
                    begin
                       if ( selm_wb_ack || selm_wb_err  )
                         begin
                            // The transaction can finish straight away if the slave has a combinatorial path
                            // between its inputs and its wb_ack or wb_err signals. This means that the wb_stb
                            // and wb_ack/wb_err signals will be asserted just for one clock posedge.
                            // Examples where this happens are memories that do asynchronous reads or slaves that are
                            // hard-wired to error immediately for their whole address ranges (typical for unused slave ports).
                            if ( ENABLE_TRACING )
                              $display( "%sSingle-cycle bus transaction, master %d is connected to slave %d, address is 0x%08h, ack %d, err %d.",
                                        TRACE_PREFIX, highest_priority_requesting_master, slave_to_connect_now,
                                        selm_wb_adr, selm_wb_ack, selm_wb_err );
                         end
                       else
                         begin
                            locked_master_index <= highest_priority_requesting_master;
                            is_master_locked <= 1;

                            if ( ENABLE_TRACING )
                              begin
                                 $display( "%sBus transaction started, master %d is connected to slave %d, address is 0x%08h.",
                                           TRACE_PREFIX, highest_priority_requesting_master, slave_to_connect_now, selm_wb_adr );
                              end
                         end
                    end
                  else
                    begin
                       if ( ENABLE_TRACING )
                         $display( "%sThe bus is idle.", TRACE_PREFIX );
                    end
               end
          end

        if ( ENABLE_TRACING )
          $display( "%sClock posedge end.", TRACE_PREFIX );
     end


   initial
     begin
        // In case the reset signal is not asserted at the beginning, initialise this module properly here.
        is_master_locked = 0;
        locked_master_index = {MASTER_INDEX_WIDTH{1'bx}};

        master_must_still_be_requesting = {MASTER_COUNT{1'b0}};

        // These signals don't actually need to be initialised, but otherwise simulators like Icarus Verilog
        // or Xilinx' ISim will do one run with a value of 'x', which will trigger some asserts above.
        highest_priority_requesting_master = DEFAULT_MASTER;
        at_least_one_master_is_requesting = 0;
        master_to_connect_now = DEFAULT_MASTER;
     end

endmodule
