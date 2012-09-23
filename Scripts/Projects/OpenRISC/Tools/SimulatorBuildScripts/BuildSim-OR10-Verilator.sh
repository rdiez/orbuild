#!/bin/bash

# Copyright (C) 2011-2012 R. Diez - see the orbuild project for licensing information.

set -o errexit

source "$ORBUILD_SANDBOX/Scripts/ShellModules/StandardShellHeader.sh"
source "$ORBUILD_SANDBOX/Scripts/ShellModules/MakeJVal.sh"

if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

VERILOG_INCLUDE_DIR="$1"
shift
VERILATOR_EXE_DIR="$1"
shift
VERILATOR_EXE_FILENAME="$1"
shift

OR10_BASE_DIR="$ORBUILD_PROJECT_DIR/OR10"
TEST_BENCH_DIR="$OR10_BASE_DIR/TestBench"

pushd "$VERILATOR_EXE_DIR" >/dev/null

VERILATOR_OUTPUT_DIR="verilator_output"

declare -a INCLUDE_PATHS=(
    -I$OR10_BASE_DIR/TestBench
    -I$OR10_BASE_DIR/WishboneSwitch
    -I$OR10_BASE_DIR/Memory
    -I$OR10_BASE_DIR/CPU
    -I$OR10_BASE_DIR/Misc
  )

TOP_LEVEL_MODULE="test_bench"

CMD="verilator"
CMD+=" ${INCLUDE_PATHS[@]}"
CMD+=" --Mdir \"$VERILATOR_EXE_DIR\""
CMD+=" -sv --cc --exe"
CMD+=" --autoflush"  # Reduces performance, but allows you to see more accurately where the simulation hangs.
CMD+=" -Wall -Wno-fatal --error-limit 10000"
CMD+=" -O3 --assert"
CMD+=" \"$TOP_LEVEL_MODULE.v\""
CMD+=" \"$TEST_BENCH_DIR/test_bench_verilator_driver.cpp\""
CMD+=" -o \"$VERILATOR_EXE_FILENAME\""

printf "$CMD\n\n"
eval "$CMD"

get_make_j_val MAKE_J_VAL

# Debug flags: export OPT="-O0 -g -Wall -Wwrite-strings -DDEBUG"
export OPT="-O3 -g -Wall -Wwrite-strings -DNDEBUG"

CMD="make -f \"V$TOP_LEVEL_MODULE.mk\" -j \"$MAKE_J_VAL\""
printf "$CMD\n\n"
eval "$CMD"

popd >/dev/null
