
// Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

#include <simulator-commands.h>


// The 'volatile' attribute should turn off compile-time optimisation
// and let the code access those variables every time they are referenced.

static const volatile int s_zero;  // Should be zero if the BSS is initialised correctly.
static const volatile int s_456 = 456;


static int start_test ( void )
{
  return s_zero + s_456 - 456;
}


int main ( void )
{
  simulation_exit( start_test() );
  
  return 0x12345678;  // We should never reach this line.
}

