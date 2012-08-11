#!/bin/bash

# Copyright (C) 2011-2012 R. Diez - see the orbuild project for licensing information.

set -o errexit

source "$ORBUILD_SANDBOX/Scripts/ShellModules/StandardShellHeader.sh"

if [ $# -ne 3 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

VERILOG_INCLUDE_DIR="$1"
shift
IVERILOG_EXE_DIR="$1"
shift
IVERILOG_EXE_FILENAME="$1"
shift

OR10_BASE_DIR="$ORBUILD_PROJECT_DIR/OR10"
TEST_BENCH_DIR="$OR10_BASE_DIR/TestBench"

pushd "$IVERILOG_EXE_DIR" >/dev/null

TOP_LEVEL_MODULE="test_bench_iverilog_driver"

declare -a INCLUDE_PATHS=(
    -y $TEST_BENCH_DIR

    -I $OR10_BASE_DIR/WishboneSwitch
    -y $OR10_BASE_DIR/WishboneSwitch

    -y $OR10_BASE_DIR/Memory

    -I $OR10_BASE_DIR/CPU
    -y $OR10_BASE_DIR/CPU

    -I $OR10_BASE_DIR/UART
    -y $OR10_BASE_DIR/UART

    -y $OR10_BASE_DIR/JTAG

    -I $OR10_BASE_DIR/Misc
    -y $OR10_BASE_DIR/Misc
  )

COMPILE_CMD="iverilog"
COMPILE_CMD+=" -Wall -Wno-timescale"
COMPILE_CMD+=" -gno-std-include"
COMPILE_CMD+=" -gsystem-verilog"  # -g2005 does work, -g2009 does not (as of July 2012) and -gsystem-verilog seems to add little interesting.
COMPILE_CMD+=" -o $IVERILOG_EXE_FILENAME"
COMPILE_CMD+=" ${INCLUDE_PATHS[@]}"
COMPILE_CMD+=" $TEST_BENCH_DIR/$TOP_LEVEL_MODULE.v"

printf "$COMPILE_CMD\n\n"
eval "$COMPILE_CMD"

popd >/dev/null
