
# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

# If you need more GNU Make routines, take a look at GMSL (GNU Make Standard Library), at http://gmsl.sourceforge.net/

# Include this file only once.
ifeq ($(origin MAKE_UTILS_INCLUDED),undefined)
MAKE_UTILS_INCLUDED := "file already included"


verify_variable_is_defined = $(if $(filter undefined,$(origin $(1))),$(error "The variable '$(1)' is not defined, but it should be at this point."))


endif  # Include this file only once.
