
// Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

#include <simulator-commands.h>


// The 'volatile' attribute should turn off compile-time optimisation
// and let the code access those variables every time they are referenced.

static volatile const int val123 = 123;
static volatile const int val246 = 246;

class MyClassA
{
public:
  int m_val;
  
  MyClassA ( void )
  {
    m_val = val246 - val123;
  }
};


static const MyClassA instance1;


static int start_test ( void )
{
  try
  {
    if ( val123 )
      throw val123;
  }
  catch ( const int a )
  {
    return instance1.m_val - a;
  }

  // We should never reach this line.
  return 1;
}


int main ( void )
{
  simulation_exit( start_test() );
  
  return 0x12345678;  // We should never reach this line.
}
