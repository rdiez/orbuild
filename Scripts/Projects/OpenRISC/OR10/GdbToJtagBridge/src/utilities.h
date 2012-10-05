
#ifndef _UTILITIES_H_
#define _UTILITIES_H_

#include <time.h>    // For timer_t.
#include <signal.h>  // For sigevent.
#include <stdint.h>  // For intptr_t.


struct timeout_timer
{
	timer_t timer_id;
	struct sigevent sev;
	struct itimerspec wait_time;
	struct itimerspec remaining_time;
};

void create_timer ( timeout_timer * timer );
bool timedout(timeout_timer * timer);
void destroy_timer ( const timeout_timer * timer );


inline bool is_aligned_4_ptr ( const void * const p )
{
  return 0 == ( intptr_t( p ) & 0x03 );
}

inline bool is_aligned_4_len ( const uint32_t len )
{
  return 0 == ( len & 0x03 );
}

#endif
