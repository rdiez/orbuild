
// This component is a fake, it does not really work and is designed
// just to let the CPU sources compile without warnings when ENABLE_EXTERNAL_MULTIPLIER == 0.
// See the readme file for more information.

`include "simulator_features.v"

module or10_external_multiplier ( input wire clk,
                                  input wire [32 : 0]  a,
                                  input wire [32 : 0]  b,
                                  output wire [65 : 0] p );

  assign p = 66'h_deadf00d_deadf00d;

  wire prevent_unused_warning_with_verilator;

  assign prevent_unused_warning_with_verilator = &{ 1'b0, a, b, 1'b0 };

   always @(clk)
     begin
        if ( a != 0 && b != 0)
          begin
             `ASSERT_FALSE;
          end
     end

endmodule
