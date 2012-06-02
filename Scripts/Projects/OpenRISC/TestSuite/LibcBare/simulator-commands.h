
// Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.


__inline__ void simulation_report ( const unsigned int value )
{
  __asm__ __volatile__ ( "l.addi r3, %0, 0 \n"
                         "l.nop %1": : "r" (value), "K" ( 2 /* NOP_REPORT */ ) );
}

__inline__ void simulation_exit ( const unsigned int exit_code )
{
  __asm__ __volatile__ ( "l.addi r3, %0, 0 \n"
                         "l.nop %1": : "r" (exit_code), "K" ( 1 /* NOP_EXIT */ ) );
}
