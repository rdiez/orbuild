#!/bin/bash

# Xilinx' settings64.sh (as of version 13.4) poisons the environment in such a way
# that other non-Xilinx programs fail to run afterwards.
#
# In order to prevent this kind of problem, this wrapper script sources settings64.sh
# just to run the given Xilinx tool. The first argument to this script is the Xilinx
# tool to run, like "fuse". All other arguments are passed to that tool.
#
# You need to set environment variable ORBUILD_XILINX_HOME beforehand, for example:
#  export ORBUILD_XILINX_HOME=/opt/Xilinx/13.4

# Copyright (C) 2012 R. Diez - see the orbuild project for licensing information.


# I hope setting the errexit flag does not interfere with the sourcing of settings64.sh in the future.
set -o errexit


abort ()
{
    echo >&2 && echo "Error in script \"$0\": $*" >&2
    exit 1
}

verify_var_is_set ()
{
    # $1 = variable name

    [ "${!1-first}" == "${!1-second}" ] || abort "Variable \"$1\" is not set, aborting."
}


if [ $# -lt 1 ]; then
    abort "Invalid number of command-line arguments, see the source code for details."
fi


TOOL_NAME="$1"
shift

verify_var_is_set "ORBUILD_XILINX_HOME"


# Note that sourcing settings64.sh is tricky (as of version 13.4), you need to clear the arguments first.
# However, we need them later, so save them here before clearing them.
declare -a SAVED_CMD_ARGS=("$@")
shift $#

source $ORBUILD_XILINX_HOME/ISE_DS/settings64.sh

exec "$TOOL_NAME" ${SAVED_CMD_ARGS[@]}
