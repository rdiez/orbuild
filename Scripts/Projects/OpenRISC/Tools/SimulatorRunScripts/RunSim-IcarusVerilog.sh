#!/bin/bash

# Copyright (C) 2011-2012 R. Diez - see the orbuild project for licensing information.

set -o errexit

source "$ORBUILD_SANDBOX/Scripts/ShellModules/StandardShellHeader.sh"

if [ $# -ne 4 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

IVERILOG_EXE_FILENAME="$1"
shift
SIM_DIRNAME="$1"
shift
SIM_FILENAME="$1"
shift
MAX_SIMULATION_TIME_IN_CLOCK_TICKS="$1"
shift

pushd "$SIM_DIRNAME" >/dev/null

FIRMWARE_SIZE_IN_BYTES="$(wc -w <"$SIM_FILENAME.hex")"

RUN_CMD="vvp"
RUN_CMD+=" $IVERILOG_EXE_FILENAME"
RUN_CMD+=" +file_name=$SIM_FILENAME.hex +firmware_size=$FIRMWARE_SIZE_IN_BYTES"
RUN_CMD+=" +max_simulation_time_in_clock_ticks=$MAX_SIMULATION_TIME_IN_CLOCK_TICKS"
RUN_CMD+=" -lxt2"

printf "$RUN_CMD\n\n"
eval "$RUN_CMD"

popd >/dev/null
