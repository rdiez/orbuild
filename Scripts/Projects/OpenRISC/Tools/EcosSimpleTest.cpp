 
#include <stdio.h>

#include <simulator-commands.h>


int main( void )
{
    simulation_report(1);
    simulation_report(2);
    simulation_report(3);

    printf( "Hello World\n\r" );
    
    simulation_exit(0);

    // Actually, we should never reach this point.
    return 0;
}
