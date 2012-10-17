
// Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

// The 'volatile' attribute should turn off compile-time optimisation
// and let the code access those variables every time they are referenced.

#include <simulator-commands.h>


static const volatile int s_zero;  // Should be zero if the BSS is initialised correctly.

static const volatile int s_123 = 123;


int main ( void )
{
  // Perform a 64-bit modulo (reminder) operation. This verifies that __umoddi3 and the like
  // from libgcc are available to do such arithmetic at runtime.
  // Note that, if you don't use 'volatile' below, the compiler calculates
  // the result at compilation time and does not use any such runtime support.
  const volatile unsigned long long a = 0x200000000 + 16 * 4 + 3;  // Some big number that yields a reminder of 3.
  const volatile unsigned long long b = 4;
  simulation_report( a / b );
  simulation_report( a % b );

  return s_zero + s_123 - 123;
}
