
#ifndef _CABLE_PARALLEL_H_
#define _CABLE_PARALLEL_H_

#include "cable_driver_common.h"

jtag_cable_t * cable_xpc3_get_driver ( void );
jtag_cable_t * cable_bb2_get_driver  ( void );
jtag_cable_t * cable_xess_get_driver ( void );

#endif
