
// Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

// The 'volatile' attribute should turn off compile-time optimisation
// and let the code access those variables every time they are referenced.

static const volatile int s_zero;  // Should be zero if the BSS is initialised correctly.

static const volatile int s_123 = 123;


int main ( void )
{
  return s_zero + s_123 - 123;
}
