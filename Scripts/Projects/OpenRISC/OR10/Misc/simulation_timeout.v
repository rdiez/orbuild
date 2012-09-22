
/* Use this module to limit the time the simulation runs. Otherwise,
   a bug in the simulation might let it freeze or run forever,
   which is always undesirable, specially during a daily build.

   The simulation timeout is based on the simulated clock ticks,
   and not real (wall clock) time, in order to be independent from
   the computer's speed and current workload.

   If your simulator supports the "final" construct (note that Verilator does),
   then the number of elapsed clock ticks will be printed at the end
   of the simulation. That can help you figure out a resonable tick count limit.


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


module simulation_timeout ( input wire clock );

   integer max_clock_tick_count;
   integer clock_tick_count = 0;

   initial
     begin
        // Force the user to always specify a clock tick limit, so that nobody ever forgets.
        // Use a value of '0' to disable the simulation timeout limit.

        if ( $value$plusargs("max_simulation_time_in_clock_ticks=%d", max_clock_tick_count) == 0 )
          begin
             $display("ERROR: Please specify the maximum simulation time in clock ticks. Otherwise, the simulation might run forever.");
             $finish;
          end
     end

   always @( posedge clock )
     begin

        if ( max_clock_tick_count != 0 && clock_tick_count > max_clock_tick_count )
          begin
             $display( "The number of clock ticks exceeded the maximum of %0d ticks, ending the simulation.", max_clock_tick_count );
             `FINISH_WITH_ERROR_EXIT_CODE;
          end

        clock_tick_count <= clock_tick_count + 1;
     end

  `ifdef SUPPORTS_FINAL
     final
       begin
          if ( max_clock_tick_count == 0 || clock_tick_count < max_clock_tick_count )
            $display( "Simulation elapsed time: %0d clock ticks.", clock_tick_count );
       end
   `endif

endmodule
