#!/bin/bash

# Copyright (C) 2011 R. Diez - see the orbuild project for licensing information.

set -o errexit

source "$(dirname $0)/../../../ShellModules/StandardShellHeader.sh"
source "$(dirname $0)/../../../ShellModules/PrintCommand.sh"
source "$(dirname $0)/../../../ShellModules/FileUtils.sh"

if [ $# -ne 5 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

MINSOC_CHECKOUT_DIR="$1"
shift
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

print_command $RUN_CMD
eval $RUN_CMD

popd >/dev/null
