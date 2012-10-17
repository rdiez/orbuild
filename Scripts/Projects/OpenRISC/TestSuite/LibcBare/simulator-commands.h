
// Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

#define NOPCODE_EXIT   1
#define NOPCODE_REPORT 2


__inline__ void simulation_report ( const unsigned int value )
{
  __asm__ __volatile__ ( "l.addi r3, %[value], 0 \n"
                         "l.nop %[nop_report]"
                         // Output operand list.
                         :
                         // Input operand list.
                         : [value] "r" (value), [nop_report] "K" ( NOPCODE_REPORT )
                         // Clobber list.
                         : "r3" );
}

__inline__ void simulation_exit ( const unsigned int exit_code )
{
  __asm__ __volatile__ ( "l.addi r3, %0, 0 \n"
                         "l.nop %1"
                         : : "r" (exit_code), "K" ( NOPCODE_EXIT ) : "r3" );
}
