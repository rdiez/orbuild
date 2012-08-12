
// Provide the clock and reset signals to the OR10 test bench
// when running under Icarus Verilog.
//
// Copyright (c) 2012, R. Diez

`timescale 1ns/100ps  // 25 MHz ->  40 ns cycle length

`define NS_IN_SEC  1_000_000_000
`define HZ_IN_MHZ  1_000_000

`define FREQ_IN_MHZ 25  // This frequency does not matter much for simulation purposes.
`define FREQ_IN_HZ ( `FREQ_IN_MHZ * `HZ_IN_MHZ )
`define CLK_PERIOD ( `NS_IN_SEC / `FREQ_IN_HZ )


module test_bench_iverilog_driver;

   reg clock, reset;

   integer reset_hold_time = 0;  // Number of rising clock edges the reset signal will be asserted.
                                 // Set it to 0 in order to start the simulation without asserting the reset signal,
                                 // which is handy to simulate FPGA designs without user reset signal that optimise away
                                 // the whole reset logic.
   initial
     begin
        clock = 0;
        reset = reset_hold_time > 0 ? 1 : 0;
     end

   always
     begin
        // $display( "Clk period: %d", `CLK_PERIOD );
        #((`CLK_PERIOD)/2) clock <= ~clock;
     end

   always @( posedge clock )
     begin
        if ( reset_hold_time > 1 )
          begin
             reset <= 1;
             reset_hold_time <= reset_hold_time - 1;
          end
        else
          begin
             reset <= 0;
          end
     end

   test_bench test_bench_instance ( .clock(clock),
                                    .reset(reset) );
endmodule
