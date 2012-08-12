
// Copyright (c) 2012, R. Diez

#define __STDC_LIMIT_MACROS
#define __STDC_FORMAT_MACROS  // For PRIu64

#include <stdint.h>
#include <limits.h>
#include <inttypes.h>  // For PRIu64

#include "Vtest_bench.h"


static uint64_t current_simulation_time = 0;

double sc_time_stamp ()
{
  return double( current_simulation_time );
} 


int main ( int argc, char ** argv, char ** env )
{
  Verilated::commandArgs( argc, argv );  // Remember args for $value$plusargs() and the like.
  Verilated::debug( 0 );  // Comment from Verilator example: "We compiled with it on for testing, turn it back off"

  Vtest_bench * const top = new Vtest_bench;

  const uint64_t reset_duration = 0;  // Number of rising clock edges the reset signal will be asserted,
                                      // set it to 0 in order to start the simulation without asserting the reset signal
                                      // (handy to simulate FPGA designs without user reset signal).
  
  top->reset = reset_duration > 0 ? 1 : 0;

  while ( !Verilated::gotFinish() )
  {
    // printf( "Iteration, clock: current_simulation_time %" PRIu64 "\n", current_simulation_time );
    // printf( "Reset: %d\n", top->reset );
    
    if ( current_simulation_time >= reset_duration * 2 )
    {
      top->reset = 0;  // Deassert reset.
    }

    top->clock = !top->clock;
    
    top->eval();
    
    ++current_simulation_time;

    // Provide an early warning against the remote possibility of a wrap-around.
    assert( current_simulation_time < UINT64_MAX / 100000 );
  }

  top->final();

  return 0;
}

