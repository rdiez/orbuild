
#include "utilities.h"  // Include file for this module should come first.

#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#include <stdexcept>

#include "errcodes.h"
#include "string_utils.h"


void create_timer ( timeout_timer * const timer )
{
	// First timer alarm.
	timer->wait_time.it_value.tv_sec  = 1;
	timer->wait_time.it_value.tv_nsec = 0;

    // Continuous timer alarm -> 0 (we only want one alarm).
	timer->wait_time.it_interval.tv_sec  = 0;
	timer->wait_time.it_interval.tv_nsec = 0;

    memset( &timer->sev, 0, sizeof( timer->sev ) );  // Initialise the whole structure in order to silence Valgrind warnings.
	timer->sev.sigev_notify = SIGEV_NONE;

	const int r1 = timer_create( CLOCK_MONOTONIC, &timer->sev, &timer->timer_id );

	if ( r1 )
	{
      throw std::runtime_error( format_errno_msg( errno, "Cannot create timer: " ) );
	}

	// Remaining timer time.
	timer->remaining_time = timer->wait_time;

	const int r2 = timer_settime( timer->timer_id, 0, &timer->wait_time, NULL );

	if ( r2 )
	{
      throw std::runtime_error( format_errno_msg( errno, "Cannot set the timer: " ) );
	}
}


bool timedout ( timeout_timer * const timer )
{
    if ( 0 != timer_gettime( timer->timer_id, &timer->remaining_time ) )
	{
      throw std::runtime_error( format_errno_msg( errno, "Cannot get the timer's remaining time: " ) );
	}

	const bool timed_out = timer->remaining_time.it_value.tv_sec  == 0 &&
                           timer->remaining_time.it_value.tv_nsec == 0;

	return timed_out;
}


void destroy_timer ( const timeout_timer * const timer )
{
    if ( 0 != timer_delete( timer->timer_id ) )
        assert( false );
}
