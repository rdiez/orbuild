
// This component is a fake, it does not really work and is designed
// just to let the CPU sources compile without warnings when ENABLE_EXTERNAL_DIVIDER == 0.
// See the readme file for more information.

`include "simulator_features.v"

module or10_external_divider ( aclk,
                               s_axis_divisor_tvalid,
                               s_axis_dividend_tvalid,
                               s_axis_divisor_tready,
                               s_axis_dividend_tready,
                               m_axis_dout_tvalid,
                               s_axis_divisor_tdata,
                               s_axis_dividend_tdata,
                               m_axis_dout_tdata );
   input aclk;
   input s_axis_divisor_tvalid;
   input s_axis_dividend_tvalid;
   output s_axis_divisor_tready;
   output s_axis_dividend_tready;
   output m_axis_dout_tvalid;
   input [39 : 0] s_axis_divisor_tdata;
   input [39 : 0] s_axis_dividend_tdata;
   output [79 : 0] m_axis_dout_tdata;

   assign s_axis_divisor_tready = 1;
   assign s_axis_dividend_tready = 1;
   assign m_axis_dout_tvalid = 1;
   assign m_axis_dout_tdata = 80'h_deadf00d_deadf00d;


  wire prevent_unused_warning_with_verilator;

  assign prevent_unused_warning_with_verilator = &{ 1'b0,
                                                    s_axis_divisor_tvalid,
                                                    s_axis_dividend_tvalid,
                                                    s_axis_divisor_tdata,
                                                    s_axis_dividend_tdata,
                                                    1'b0 };

   always @(aclk)
     begin
        if ( s_axis_divisor_tvalid ||s_axis_dividend_tvalid )
          begin
             `ASSERT_FALSE;
          end
     end

endmodule
