
#ifndef CABLE_WRITE_BIT_CONSTANTS_H_INCLUDED
#define CABLE_WRITE_BIT_CONSTANTS_H_INCLUDED

// These constants need to be accessible for both the external API user and the internal driver implementations.


// Constants to use in the 'packet' args of cable_write_bit() and cable_read_write_bit().
#define TRST     (0x04)  // Note that while TRST is active low for JTAG hardware, but here the TRST bit
                         // should be set when you want the TRST wire active.
#define TMS      (0x02)
#define TDO      (0x01)

#endif  // Include this header file only once.
