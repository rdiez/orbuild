
AC_INIT([OpenRiscTestSuite],[2012-04-21])
AC_PREREQ([2.65])  # Tested mainly with version 2.68.

AM_INIT_AUTOMAKE([-Wall -Werror])
LT_INIT

# Silent rules support. Disabled at the moment, when developing the test suite it's generally useful to see all flags.
#   Use "make V=1" in order to see the gcc command-lines during compilation.
#   m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])


# These compilation flags must be set before AC_PROG_CC/CXX, or you'll get the default "-g -O2".
CFLAGS="${CFLAGS=} -g -Wall -mhard-div -mhard-mul -nostdlib -T $srcdir/AsmTestEnvironment/LinkerScript.ld"
CPPFLAGS="-I$srcdir/AsmTestEnvironment"

AM_PROG_AS
AC_PROG_CC_STDC  # AC_PROG_CC would probably be fine too.
AC_PROG_INSTALL

AC_CONFIG_MACRO_DIR([m4])


# ----------- Check whether debug or release build -----------

AC_MSG_CHECKING(whether to generate a debug build)
AC_ARG_ENABLE([debug],
              [AS_HELP_STRING([--enable-debug=[[yes/no]]],
                              [generate a debug build with assertions and no optimization [default=no]])],
              [case "${enableval}" in
               yes) debug_build=true ;;
               no)  debug_build=false ;;
               *) AC_MSG_ERROR([bad value ${enableval} for --enable-debug]) ;;
               esac],
              debug_build=false)

if [ test x$debug_build = xtrue ]
then
    AC_MSG_RESULT(yes)
    CFLAGS="$CFLAGS -O0 -DDEBUG"
else
    AC_MSG_RESULT(no)
    # If we let the 'omit frame pointer' optimisation enabled,
    # we'll have difficulty later on while trying
    # to analyse crash dump files sent by the users.
    CFLAGS="$CFLAGS -O2 -DNDEBUG -fno-omit-frame-pointer"
fi


# If you update this line, please update SUBDIRS in Makefile.am too.
AC_CONFIG_FILES([Makefile AsmTestCases/Makefile LibcBare/Makefile CTestCases/Makefile])

AC_OUTPUT
