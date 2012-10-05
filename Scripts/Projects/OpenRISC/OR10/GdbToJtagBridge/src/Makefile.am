
AM_CPPFLAGS =

bin_PROGRAMS = or10_gdb_to_jtag_bridge

or10_gdb_to_jtag_bridge_SOURCES = \
  main.cpp \
  rsp_server.cpp \
  rsp_or10.cpp \
  rsp_string_helpers.cpp \
  rsp_packet_helpers.cpp \
  chain_commands.cpp \
  cable_api.cpp \
  bsdl.cpp \
  bsdl_parse.cpp \
  errcodes.cpp \
  dbg_api.cpp \
  utilities.cpp \
  string_utils.cpp \
  linux_utils.cpp \
  cable_drivers/cable_driver_common.cpp \
  cable_drivers/cable_simulation_with_predefined_file.cpp \
  cable_drivers/cable_simulation_over_tcp_socket.cpp


or10_gdb_to_jtag_bridge_LDFLAGS = -lpthread -lrt

if SUPPORT_PARALLEL_CABLES
  AM_CPPFLAGS += -D__SUPPORT_PARALLEL_CABLES__
  or10_gdb_to_jtag_bridge_SOURCES  += cable_drivers/cable_parallel.cpp
endif

if SUPPORT_FTDI_CABLES
  AM_CPPFLAGS += -D__SUPPORT_FTDI_CABLES__
  or10_gdb_to_jtag_bridge_LDFLAGS  += -lftdi
  or10_gdb_to_jtag_bridge_SOURCES  += cable_drivers/cable_ft2232.cpp cable_drivers/cable_ft245.cpp
endif

# Must come after SUPPORT_FTDI_CABLES, see below.
if SUPPORT_USB_CABLES
  AM_CPPFLAGS += -D__SUPPORT_USB_CABLES__
  or10_gdb_to_jtag_bridge_SOURCES  += cable_drivers/cable_xpc_dlc9.cpp cable_drivers/cable_usbblaster.cpp
  # libusb must follow libftdi in the list of libraries
  or10_gdb_to_jtag_bridge_LDFLAGS  += -lusb
endif

if INCLUDE_JSP_SERVER
  AM_CPPFLAGS += -DENABLE_JSP
  or10_gdb_to_jtag_bridge_SOURCES  += jsp_server.cpp
endif
