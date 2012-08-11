#!/bin/bash

# Copyright (C) 2011-2012 R. Diez - see the orbuild project for licensing information.

set -o errexit

source "$ORBUILD_SANDBOX/Scripts/ShellModules/StandardShellHeader.sh"

if [ $# -ne 4 ]; then
  abort "Invalid number of command-line arguments, see the source code for details."
fi

ORPSOCV2_CHECKOUT_DIR="$1"
shift
VERILOG_INCLUDE_DIR="$1"
shift
IVERILOG_EXE_DIR="$1"
shift
IVERILOG_EXE_FILENAME="$1"
shift

TEST_BENCH_DIR="$ORPSOCV2_CHECKOUT_DIR/bench/verilog"

pushd "$IVERILOG_EXE_DIR" >/dev/null

# The test framework may generate files like test-defines.v and or1200_defines.v,
# and the generated files should have precedence over any other files with the same name,
# therefore this include path must come first.
OR1200_INCLUDE=" -I$VERILOG_INCLUDE_DIR"

OR1200_INCLUDE+=" -I$ORPSOCV2_CHECKOUT_DIR/sim/vlt"
OR1200_INCLUDE+=" -I$ORPSOCV2_CHECKOUT_DIR/rtl/verilog/include"
OR1200_INCLUDE+=" -I$ORPSOCV2_CHECKOUT_DIR/bench/verilog/include"
OR1200_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/or1200"

ORPSOC_INCLUDE=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/clkgen"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/arbiter"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/uart16550"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/intgen"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/ram_wb"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/dbg_if"
ORPSOC_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/jtag_tap"

TESTBENCH_INCLUDE=" -I$ORPSOCV2_CHECKOUT_DIR/sim/bin"
TESTBENCH_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/rtl/verilog/orpsoc_top"
TESTBENCH_INCLUDE+=" -y $ORPSOCV2_CHECKOUT_DIR/bench/verilog"

ALL_INCLUDES="$OR1200_INCLUDE $ORPSOC_INCLUDE $TESTBENCH_INCLUDE"

COMPILE_CMD="iverilog"
COMPILE_CMD+=" -gno-std-include"
COMPILE_CMD+=" -Wall -Wno-timescale"
COMPILE_CMD+=" -g2001"
COMPILE_CMD+=" -o $IVERILOG_EXE_FILENAME"
COMPILE_CMD+=" $ALL_INCLUDES "
COMPILE_CMD+=" $TEST_BENCH_DIR/orpsoc_testbench.v"

printf "$COMPILE_CMD\n\n"
eval "$COMPILE_CMD"

popd >/dev/null
