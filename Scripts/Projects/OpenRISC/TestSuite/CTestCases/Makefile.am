
# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.

bin_PROGRAMS = c-basic

c_basic_SOURCES  = c-basic.c

# With Peter Gavin's toolchain based on GCC 4.8.0, the ENTRY(_start) command in the linker script file
# is apparently not enough for the linker to pull startup.o from the libc-bare.a library.
# There is no warning or error message, the resulting executable is empty (!).
# In order to prevent that from happening, we need to explicitly list startup.o in the list of objects to link.
#
# Another work-around would probably be specifying both "-e _start" (or "--undefined=_start") and "-u _start" (or "--entry=_start")
# in the linker command line. Alternatively, the linker script file could specify the EXTERN(_start) command (which is equivalent to "--entry=_start"),
# in addition to ENTRY(_start).
# I found the following excerpt on the Internet about this issue:
#
#  Re: crt0.o and _start symbol
#  From: Ian Lance Taylor <iant at google dot com>
#  The answer is that -e does not imply -u, although that is likely to
#  change in the next binutils release.  Most systems link against crt0.o explicitly.
#
#   c_basic_LDADD = ../LibcBare/libc-bare.a
c_basic_LDADD = ../LibcBare/startup.o

dist_data_DATA = single-exit-0.TestResults
