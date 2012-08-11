#!/bin/bash

# Copyright (C) 2011-2012 R. Diez - see the orbuild project for licensing information.

set -o errexit

source "$ORBUILD_SANDBOX/Scripts/ShellModules/StandardShellHeader.sh"

if [ $# -ne 5 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

ISIM_EXE_DIR="$1"
shift
ISIM_EXE_FILENAME="$1"
shift
SIM_DIRNAME="$1"
shift
SIM_FILENAME="$1"
shift
MAX_SIMULATION_TIME_IN_CLOCK_TICKS="$1"
shift

# Several instances of the simulator may be running concurrently, so place all possible
# output files in the simulation directory.
BATCH_FILENAME="$SIM_DIRNAME/RunSimulationBatchFileForISim.tcl"
LOG_FILENAME="$SIM_DIRNAME/isim.log"
WDB_FILENAME="$SIM_DIRNAME/isim.wdb"
VCD_FILENAME="$SIM_DIRNAME/isim.vcd"

pushd "$ISIM_EXE_DIR" >/dev/null

FIRMWARE_SIZE_IN_BYTES="$(wc -w <"$SIM_DIRNAME/$SIM_FILENAME.hex")"

echo "run all" >"$BATCH_FILENAME"

RUN_CMD="$ORBUILD_PROJECT_DIR/Tools/RunXilinxTool.sh $ISIM_EXE_FILENAME"
RUN_CMD+=" -tclbatch $BATCH_FILENAME"
RUN_CMD+=" -wdb $WDB_FILENAME"
RUN_CMD+=" -log $LOG_FILENAME"
RUN_CMD+=" -vcdfile $VCD_FILENAME"
RUN_CMD+=" -testplusarg file_name=$SIM_DIRNAME/$SIM_FILENAME.hex -testplusarg firmware_size=$FIRMWARE_SIZE_IN_BYTES"
RUN_CMD+=" -testplusarg max_simulation_time_in_clock_ticks=$MAX_SIMULATION_TIME_IN_CLOCK_TICKS"

printf "$RUN_CMD\n\n"
eval "$RUN_CMD"

popd >/dev/null
