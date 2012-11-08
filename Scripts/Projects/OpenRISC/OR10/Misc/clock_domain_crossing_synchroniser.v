
// Copyright (C) 2012 -  R. Diez
//
// At the moment, this module is just a fancy name for a shift register,
// but in the future it could use chip-specific mechanism specifically
// designed for clock domain crossing.
//
// If your silicon library supports metastable-hardened ﬂip-ﬂops, then the ﬁrst stage
// here should use such a device. Typically, metastable-hardened ﬂip-ﬂops guarantee
// that their Q outputs will settle after a given maximum time, no matter how close
// the data transition is to the ﬂip-ﬂop’s clock edge.
//
// If your silicon library supports it, another possibility would be to use a dual-clocked FIFO.

module clock_domain_crossing_synchroniser

   #( parameter FLIP_FLOP_COUNT = 2,
      parameter INITIAL_VALUE   = 0 )

   ( input  dest_domain_clock,
     input  signal_in_foreign_clock_domain,
     output synchronised_signal );

  reg [FLIP_FLOP_COUNT-1:0] shift_reg;

  always @( posedge dest_domain_clock )
    begin
       shift_reg <= { signal_in_foreign_clock_domain, shift_reg[FLIP_FLOP_COUNT-1:1] };
    end

   assign synchronised_signal = shift_reg[0];

   integer i;

   initial
     begin
        for ( i = 0; i < FLIP_FLOP_COUNT; i = i + 1 )
          shift_reg[i] = INITIAL_VALUE;
     end
endmodule
