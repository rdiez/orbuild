/* JTAG protocol bridge between GDB and OR10.

   Copyright(C) 2001 Marko Mlinar, markom@opencores.org
   Code for TCP/IP copied from gdb, by Chris Ziomkowski
   Refactoring by Nathan Yawn <nyawn@opencores.org> (C) 2008 - 2010
   Conversion to C++, reorganisation and port to OR32 by R. Diez, Copyright (C) 2012.

   This file was part of the OpenRISC 1000 Architectural Simulator.
   It is now also used to connect GDB to a running or simulated OR10 CPU.

   --------------

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <stdio.h>
#include <stdlib.h>  // for exit(), atoi(), strtoul()
#include <unistd.h>
#include <errno.h>
#include <stdarg.h>
#include <string.h>  // for strstr()
#include <sys/types.h>
#include <getopt.h>

#include <new>
#include <stdexcept>

#include "rsp_server.h"
#include "chain_commands.h"
#include "cable_api.h"
#include "bsdl.h"
#include "errcodes.h"
#include "string_utils.h"
#include "linux_utils.h"


#define debug(...) //fprintf(stderr, __VA_ARGS__ )

// How many command-line IR length settings to create by default
#define IR_START_SETS 16

//////////////////////////////////////////////////
// Command line option flags / values

// Which device in the scan chain we want to target.
// 0 is the first device we find, which is nearest the data input of the cable.
int target_dev_pos = 0;

// IR register length in TAP of
// Can override autoprobe, or set if IDCODE not supported
struct irset
{
  int dev_index;
  int ir_length;
};

#define START_IR_SETS 16
static std::vector< irset > cmd_line_ir_sizes;

// DEBUG command for target device TAP
// May actually be USER1, for Xilinx devices using internal BSCAN modules
// Can override autoprobe, or set if unable to find in BSDL files
static int cmd_line_cmd_debug = -1;  // 0 is a valid debug command, so use -1

static int listen_on_all_addrs = 0;

// TCP port to set up the server for GDB on
static const char *port = NULL;
static const char default_port[] = "9999";

#ifdef ENABLE_JSP
static const char *jspport = NULL;
static const char default_jspport[] = "9944";
#endif

// Force altera virtual jtag mode on(1) or off(-1)
static int force_alt_vjtag = 0;


// Pointer to the command line arg used as the cable name
static const char * cable_name = NULL;

// List of IDCODES of devices on the JTAG scan chain, invalid ones will have a value of IDCODE_INVALID.
static std::vector< uint32_t > discovered_id_codes;


static const char * const name_not_found = "(unknown)";


///////////////////////////////////////////////////////////
// JTAG constants

// Defines for Altera JTAG constants
#define ALTERA_MANUFACTURER_ID   0x6E

// Defines for Xilinx JTAG constants
#define XILINX_MANUFACTURER_ID   0x49


static int get_IR_size ( const int devidx )
{
  int retval = -1;

  if( discovered_id_codes[devidx] != IDCODE_INVALID )
  {
    retval = bsdl_get_IR_size(discovered_id_codes[devidx]);
  }

  // Search for this devices in the array of command line IR sizes
  for(unsigned i = 0; i < cmd_line_ir_sizes.size(); i++)
  {
    if(cmd_line_ir_sizes[i].dev_index == devidx)
    {
      if ( (retval > 0) && (retval != cmd_line_ir_sizes[i].ir_length) )
      {
        printf("Warning: overriding autoprobed IR length (%i) with command line value (%i) for device %i\n", retval,
               cmd_line_ir_sizes[i].ir_length, devidx);
      }

      retval = cmd_line_ir_sizes[i].ir_length;
    }
  }

  if(retval < 0)
  {
    printf("ERROR! Unable to autoprobe IR length for device index %i;  Must set IR size on command line. Aborting.\n", devidx);
    exit(1);
  }

  return retval;
}


static uint32_t get_debug_cmd ( const int devidx )
{
  int retval = TAP_CMD_INVALID;
  const uint32_t manuf_id = (discovered_id_codes[devidx] >> 1) & IDCODE_MANUFACTURER_ID_MASK;

  if ( discovered_id_codes[devidx] != IDCODE_INVALID )
  {
    if ( manuf_id == XILINX_MANUFACTURER_ID )
    {
      retval = bsdl_get_user1_cmd( discovered_id_codes[devidx] );
      if(cmd_line_cmd_debug < 0)
        printf( "Xilinx manufacturer code found in the device's IDCODE, assuming Xilinx' internal JTAG (BSCAN mode, using USER1 instead of DEBUG TAP command).\n" );
    }
    else
    {
      retval = bsdl_get_debug_cmd(discovered_id_codes[devidx]);
    }
  }

  if(cmd_line_cmd_debug >= 0)
  {
    if ( retval != int(TAP_CMD_INVALID) )
    {
      printf("Warning: overriding autoprobe debug command (0x%X) with command line value (0x%X)\n", retval, cmd_line_cmd_debug);
    }
    else
    {
      printf("Using command-line debug command 0x%X\n", cmd_line_cmd_debug);
    }
    retval = cmd_line_cmd_debug;
  }

  if(retval == int(TAP_CMD_INVALID))
  {
    printf("ERROR!  Unable to find DEBUG command for device index %i, device ID 0x%0X\n", devidx, discovered_id_codes[devidx]);
  }

  return retval;
}


// Resets JTAG, and sets up DEBUG scan chain
static void configure_chain ( void )
{
  printf( "Resetting the JTAG interface...\n" );
  tap_reset();

  printf( "Enumerating the JTAG chain...\n" );
  jtag_enumerate_chain( &discovered_id_codes );

  printf("\nDevices discovered on the JTAG chain:\n");
  printf("Index\tName\t\tID Code\t\tIR Length\n");
  printf("----------------------------------------------------------------\n");

  for( unsigned i = 0; i < discovered_id_codes.size(); i++ )
  {
    const char * name;
    int irlen;

    if ( discovered_id_codes[i] != IDCODE_INVALID )
    {
      name  = bsdl_get_name   ( discovered_id_codes[i] );
      irlen = bsdl_get_IR_size( discovered_id_codes[i] );
      if ( name == NULL )
        name = name_not_found;
    }
    else
    {
      name = name_not_found;
      irlen = -1;
    }
    printf("%d: \t%s \t0x%08X \t%d\n", i, name, discovered_id_codes[i], irlen);
  }
  printf("\n");

  if ( discovered_id_codes.size() > 1 )
  {
    throw std::runtime_error( "TODO: Support for JTAG chains with more than one device must be tested again." );
  }

  if ( target_dev_pos >= int( discovered_id_codes.size() ) )
  {
    printf("ERROR: Requested target device (%i) beyond highest device index (%u).\n",
           target_dev_pos,
           unsigned( discovered_id_codes.size() - 1 )) ;
    exit(1);
  }

  printf( "The target device is at JTAG chain position %d and has an IDCODE of 0x%08X.\n",
          target_dev_pos,
          discovered_id_codes[target_dev_pos] );

  const unsigned int manuf_id = (discovered_id_codes[target_dev_pos] >> 1) & IDCODE_MANUFACTURER_ID_MASK;

  // Use BSDL files to determine prefix bits, postfix bits, debug command, IR length
  config_set_IR_size( get_IR_size(target_dev_pos) );

  // Set the IR prefix / postfix bits
  int total = 0;
  for ( int i = 0; i < int( discovered_id_codes.size() ); i++ )
  {
    if(i == target_dev_pos)
    {
      config_set_IR_postfix_bits(total);
      //debug("Postfix bits: %d\n", total);
      total = 0;
      continue;
    }

    total += get_IR_size(i);
    debug("Adding %i to total for devidx %i\n", get_IR_size(i), i);
  }
  config_set_IR_prefix_bits(total);
  debug("Prefix bits: %d\n", total);


  // Note that there's a little translation here, since device index 0 is actually closest to the cable data input
  config_set_DR_prefix_bits(int(discovered_id_codes.size()) - target_dev_pos - 1);  // number of devices between cable data out and target device
  config_set_DR_postfix_bits(target_dev_pos);  // number of devices between target device and cable data in

  // Set the DEBUG command for the IR of the target device.
  // If this is a Xilinx device, use USER1 instead of DEBUG
  // If we Altera Virtual JTAG mode, we don't care.
  if((force_alt_vjtag == -1) || ((force_alt_vjtag == 0) &&  (manuf_id != ALTERA_MANUFACTURER_ID)))
  {
    const uint32_t cmd = get_debug_cmd(target_dev_pos);
    if(cmd == TAP_CMD_INVALID)
    {
      printf("Unable to find DEBUG command, aborting.\n");
      exit(1);
    }
    config_set_debug_cmd(cmd);  // This may have to be USER1 if this is a Xilinx device
  }

  // Enable the kludge for Xilinx BSCAN, if necessary.
  // Safe, but slower, for non-BSCAN TAPs.
  if ( manuf_id == XILINX_MANUFACTURER_ID )
  {
    config_set_xilinx_bscan_internal_jtag( true );
  }

  // Set Altera Virtual JTAG mode on or off.  If not forced, then enable
  // if the target device has an Altera manufacturer IDCODE
  if(force_alt_vjtag == 1)
  {
    config_set_alt_vjtag(1);
  }
  else if(force_alt_vjtag == -1)
  {
    config_set_alt_vjtag(0);
  }
  else
  {
    if(manuf_id == ALTERA_MANUFACTURER_ID)
    {
      config_set_alt_vjtag(1);
    }
    else
    {
      config_set_alt_vjtag(0);
    }
  }

  printf( "Performing a sanity check (write the IDCODE instruction code and read back the IDCODE value)...\n" );
  const uint32_t cmd = bsdl_get_idcode_cmd( discovered_id_codes[target_dev_pos] );

  if ( cmd == TAP_CMD_INVALID )
    throw std::runtime_error( "Error: The BSDL file does not contain the IDCODE instruction opcode, which is needed for a basic sanity check." );

  uint32_t id_read;
  jtag_get_idcode( cmd, &id_read );

  if ( id_read != discovered_id_codes[target_dev_pos] )
  {
    throw std::runtime_error( format_msg( "The IDCODE sanity test has failed, the IDCODE value read was 0x%08X, but the expected code was 0x%08X.\n",
                                          id_read,
                                          discovered_id_codes[target_dev_pos] ) );
  }

  printf("IDCODE sanity test passed, the JTAG chain looks OK.\n");

  printf("Switching to the debug module of the OR10 TAP...\n");
  set_ir_to_cpu_debug_module();
}


void print_usage ( const char * const func )
{
  printf("Bridge between GDB and JTAG for the OR10 CPU.\n");
  printf("Copyright (C) 2012 R. Diez and others (see the documentation and the source code for other authors)\n\n");

#ifdef ENABLE_JSP
  printf("Compiled with support for the JTAG Serial Port (JSP).\n");
#else
  printf("Support for the JTAG serial port is NOT compiled in.\n");
#endif

  printf("\nUsage: %s (options) [cable] (cable options)\n", func);
  printf("Options:\n");
  printf("  -g [port]     : port number for GDB (default: %s)\n", default_port);
  printf("  --listen-on-all-addrs: Instead of listening just on the localhost loopback address (127.0.0.1), listen on\n"
         "                         all local IP addresses, so that the GDB server can be reached over the network.\n");
#ifdef ENABLE_JSP
  printf("  -j [port]     : port number for JSP Server (default: %s)\n", default_jspport);
#endif
  printf("  -x [index]    : Position of the target device in the scan chain\n");
  printf("  -a [0 / 1]    : force Altera virtual JTAG mode off (0) or on (1)\n");
  printf("  -l [<index>:<bits>]: Specify length of IR register for device\n");
  printf("                       <index>, override autodetect (if any)\n");
  printf("  -c [hex cmd]  : Debug command for target TAP, override autodetect\n");
  printf("                  (ignored for Altera targets)\n");
  printf("  -v [hex cmd]  : VIR command for target TAP, override autodetect\n");
  printf("                  (Altera virtual JTAG targets only)\n");
  printf("  -r [hex cmd]  : VDR for target TAP, override autodetect\n");
  printf("                  (Altera virtual JTAG targets only)\n");
  printf("  -b [dirname]  : Add a directory to search for BSDL files\n");

  printf("  -h            : show help\n\n");
  cable_print_help();
  printf("\n");
  printf("The bridge terminates upon receiving signals SIGINT (Ctrl+C) or SIGHUP (closing a console window).\n");
  printf("\n");
}


// Extracts two values from an option string
// of the form "<index>:<value>", where both args
// are in base 10
void get_ir_opts ( char * const optstr,  // Modifes this string.
                   int * const idx,
                   int * const val )
{
  char *ptr;

  ptr = strstr(optstr, ":");
  if(ptr == NULL) {
    printf("Error: badly formatted IR length option.  Use format \'<index>:<value>\', without spaces, where both args are in base 10\n");
    exit(1);
  }

  *ptr = '\0';
  ptr++;  // This now points to the second (value) arg string

  *idx = strtoul(optstr, NULL, 10);
  *val = strtoul(ptr, NULL, 10);
  // ***CHECK FOR SUCCESS
}


void parse_args ( const int argc, char ** const argv )
{
  port = NULL;
  force_alt_vjtag = 0;
  cmd_line_cmd_debug = -1;

  std::string optstring = "+g:w:x:a:l:c:v:r:b:th";

  #ifdef ENABLE_JSP
    jspport = NULL;
    optstring += "j:";
  #endif

  const struct option longopts[] =
    {
      { "help", no_argument, NULL, 'h' },
      { "listen-on-all-addrs", no_argument, &listen_on_all_addrs, 1 },
      { NULL, 0, NULL, 0 }  // All zeros, marks the end of the long options list.
    };

  for ( ; ; )
  {
    const int c = getopt_long( argc, argv,
                               optstring.c_str(),
                               longopts, NULL );
    if ( c == -1 )
      break;  // Finished parsing all command-line options.

    switch ( c )
    {
     case 0:
       // A long option was processed, nothing else to do here.
       break;

    case 'h':
      print_usage(argv[0]);
      exit(0);
      break;

    case 'g':
      port = optarg;
      break;

#ifdef ENABLE_JSP
    case 'j':
      jspport = optarg;
      break;
#endif

    case 'x':
      target_dev_pos = atoi(optarg);
      break;

    case 'l':
      {
        int idx;
        int val;
        get_ir_opts(optarg, &idx, &val);        // parse the option
        irset new_elem;

        new_elem.dev_index = idx;
        new_elem.ir_length = val;
        cmd_line_ir_sizes.push_back( new_elem );
        break;
      }

    case 'c':
      cmd_line_cmd_debug = strtoul(optarg, NULL, 16);
      break;

    case 'v':
      config_set_vjtag_cmd_vir(strtoul(optarg, NULL, 16));
      break;

    case 'r':
      config_set_vjtag_cmd_vdr(strtoul(optarg, NULL, 16));
      break;

    case 'a':
      if(atoi(optarg) == 1)
        force_alt_vjtag = 1;
      else
        force_alt_vjtag = -1;
      break;

    case 'b':
      bsdl_add_directory(optarg);
      break;

    default:
      throw std::runtime_error( "Invalid command-line arguments, use the --help switch for help.\n" );
      // print_usage( argv[0] );
      // exit(1);
    }
  }

  if(port == NULL)
    port = default_port;

#ifdef ENABLE_JSP
  if(jspport == NULL)
    jspport = default_jspport;
#endif

  bool found_cable = false;
  char * start_str = argv[optind];
  int start_idx = optind;

  for ( int i = optind; i < argc; i++ )
  {
    if ( cable_select( argv[i] ) )
    {
      found_cable = true;
      cable_name = argv[i];
      argv[optind] = argv[start_idx];  // swap the cable name with the other arg,
      argv[start_idx] = start_str;     // keep all cable opts at the end
      break;
    }
 }


  if( !found_cable )
  {
    throw std::runtime_error( "No valid cable specified." );
  }

  optind = start_idx + 1;  // Reset the parse index.

  // Parse the remaining options for the cable.
  // Note that this will include unrecognized option from before the cable name.

  const char * const valid_cable_args = cable_get_args();

  for ( ; ; )
  {
    const int c = getopt( argc, argv, valid_cable_args );

    if ( c == -1 )
      break;  // Finished parsing all command-line options.

    // printf("Got cable opt %c (0x%X)\n", (char)c, c);

    if ( c == '?' )
    {
      throw std::runtime_error( format_msg( "Unknown cable option '-%c'.", optopt ) );
    }

    cable_parse_opt( c, optarg );
  }
}


static bool s_exit_request = false;
static int s_received_signal_number;

static void exit_signal_handler ( const int signo, siginfo_t * const info, void * )
{
  s_received_signal_number = signo;
  s_exit_request = true;
}

static void ignore_signal_handler ( int , siginfo_t * , void * )
{
}


static int main_2 ( int argc,  char * argv[] )
{
  try
  {
    // This application does not output large number of text messages,
    // and, if logging is turned of, the user should see the log messages straight away.
    // Therefore, turn off buffering on stdout and stderr. Afterwards, there is no need
    // to call fflush( stdout/stderr ) any more.
    if ( 0 != setvbuf( stdout, NULL, _IONBF, 0 ) )
      throw std::runtime_error( format_errno_msg( errno, "Cannot turn off buffering on stdout: " ) );

    if ( 0 != setvbuf( stderr, NULL, _IONBF, 0 ) )
      throw std::runtime_error( format_errno_msg( errno, "Cannot turn off buffering on stderr: " ) );


    bsdl_init();

    cable_setup();

    parse_args( argc, argv );

    char * server_port_first_err_char;
    const long int gdb_rsp_server_port = strtol( port, &server_port_first_err_char, 10 );

    if ( *server_port_first_err_char )
    {
      throw std::runtime_error( format_msg( "Failed to parse GDB RSP server port from the given parameter \"%s\".", port ) );
      // This alternative code issues a warning and takes a default port number:
      //   printf( "Failed to parse GDB RSP server port \'%s\', using default \'%s\'.\n", port, default_port );
      //   gdb_rsp_server_port = strtol( default_port, &server_port_first_err_char, 10 );
      //   if ( *server_port_first_err_char )
      //     throw std::runtime_error( "Error retrieving the TCP port for the GDB RSP server." );
    }

    cable_init();

    // Initialize a new connection to the or1k board, and make sure we are really connected.
    configure_chain();

  #ifdef ENABLE_JSP
    long int jspserverport;
    jspserverport = strtol(jspport,&s,10);
    if(*s) {
      printf("Failed to get JSP server port \'%s\', using default \'%s\'.\n", jspport, default_jspport);
      serverPort = strtol(default_jspport,&s,10);
      if(*s) {
        printf("Failed to get default JSP port, exiting.\n");
        return -1;
      }
    }

    jsp_init(jspserverport);
    jsp_server_start();
  #endif

    printf("The GDB to JTAG bridge is up and running.\n");

    // If you update the signal list, please update the help text too.
    install_signal_handler( SIGINT , exit_signal_handler );
    install_signal_handler( SIGHUP , exit_signal_handler );
    install_signal_handler( SIGPIPE, ignore_signal_handler );  // Otherwise, writing to a socket may kill us with a SIGPIPE signal.

    handle_rsp( gdb_rsp_server_port, listen_on_all_addrs ? false : true, &s_exit_request );

    if ( s_exit_request )
    {
      printf( "Quitting after receiving signal number %d.\n", s_received_signal_number );
    }

    cable_close();

    bsdl_terminate();

    return 0;
  }
  catch ( ... )
  {
    bsdl_terminate();
    throw;
  }
}


int main ( int argc,  char *argv[] )
{
  std::string exit_msg_prefix;

  try
  {
    exit_msg_prefix = format_msg( "Error running \"%s\": ", argv[0] );
    return main_2( argc, argv );
  }
  catch ( const std::exception & e )
  {
    fprintf( stderr, "%s%s\n", exit_msg_prefix.c_str(), e.what() );
    return 1;
  }
}
